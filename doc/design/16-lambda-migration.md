# Lambda Migration

## Overview

This document describes moving the application runtime from ECS Fargate to AWS Lambda.

The motivation is fixed cost. The application is only needed for sign-up and for preparing map uploads; viewing is served by the storage layer and the client. A July 2026 bill (before the service was stopped) showed that always-on components dominated the cost:

| Item | Monthly (excl. tax) |
|---|---|
| RDS | $21.46 |
| ECS (Fargate, 2 services) | $18.34 |
| Elastic Load Balancing | $18.08 |
| VPC (public IPv4, about 4 addresses) | $14.89 |
| Other (Secrets Manager, S3, ECR, ...) | $0.54 |
| Total | $73.31 |

Lambda removes the Fargate, ALB and public IPv4 costs. RDS and a NAT instance remain; the target is about $30 per month.

### Current state

The service is stopped. The ALB, the application ECS service and the `app` CloudFront distribution have already been removed from AWS, as has the Gandi CNAME. RDS, the S3 buckets, the SQS queues and the `maps` distribution remain. At the time of writing, `terraform plan` showed 7 additions and 2 changes, with no deletions, so the Terraform state matched reality apart from the stopped parts.

### Non-goals

- Moving the database off RDS (the NAT instance is the price of keeping it).
- Rewriting the application in another language.
- Removing the guest cleanup code (see [Follow-ups](#follow-ups)).

## Architecture

```
Viewer -> CloudFront (app)
            |- /assets/*  -> S3 (assets, OAC)
            `- default    -> Lambda Function URL (no auth, secret header)
                               `- app function (Web Adapter + Puma)
                                    |- RDS (in VPC)
                                    `- SQS, OAuth providers (via NAT instance)

SQS (s3-cleanup, storage-calculation) -> event source mapping -> worker functions (DLQ each)
GitHub Actions -> aws lambda invoke -> task function (migrate, seed, delete map)
```

## Runtime

The managed `ruby4.0` runtime is used, deployed as a zip on arm64. At the time of writing it provides Ruby 4.0.9; the patch version is updated by AWS. The application follows the runtime, so patch differences against local and CI Ruby are accepted.

| Function | Trigger | Web Adapter |
|---|---|---|
| `app` | CloudFront via Function URL | Yes |
| `task` | `aws lambda invoke` from GitHub Actions | No |
| `s3-cleanup` | SQS | No |
| `storage-calculation` | SQS | No |

All functions share one zip. Only `app` attaches the Lambda Web Adapter layer (v30, arm64) with `AWS_LAMBDA_EXEC_WRAPPER=/opt/bootstrap`, handler `run.sh`, and Puma listening on `AWS_LWA_PORT=7000`. Port 8080 is avoided because the Lambda runtime emulator uses it; the adapter documentation also warns against 3000 and 9001.

### Package

- The zip holds `vendor/bundle`, the application code, `config.ru` and `run.sh`. Measured size is about 26 MB zipped and 69 MB unzipped, against the 250 MB limit.
- `public/assets` (about 51 MB) is served from S3. `public/` in the zip contains only the 404/500 pages and `assets/assets.json`.
- The build runs inside `public.ecr.aws/lambda/ruby:4.0` with `gcc`, `make`, `zip`, `tar` and `libyaml-devel` installed (psych builds from source), so native gems match the runtime (Amazon Linux 2023). Build artifacts (`*.o`, `*.c`, `*.h`) are removed and file modes are normalised.
- `pg` needs no system libpq: `Gemfile.lock` carries the precompiled `aarch64-linux` build, which bundles libpq.
- The `Dockerfile` is removed. ECR is no longer needed.

### Event functions

`SqsQueueWorker` polling is not used in production. The `handle` logic of each worker (calling `operations.delete_s3_prefix` or `operations.generations.calculate_storage`) is shared between the Lambda handler and the local polling worker. Failures are reported per message (`ReportBatchItemFailures`).

## Networking

All resources stay in the default VPC. Its subnets are public, and Lambda ENIs have no public IPv4 address, so a function in them cannot reach the internet even with an internet gateway. Outbound access is needed for OAuth providers (GitHub, Discord, Steam) and SQS.

- Add private subnets in two availability zones, using unused CIDR ranges of the default VPC.
- Run one fck-nat instance (t4g.nano, Auto Scaling group with min = max = 1, Elastic IP) in an existing public subnet. The private route tables send `0.0.0.0/0` to it. The fck-nat Terraform module is pinned to 1.3.0; the AWS provider has since been upgraded to `~> 6.45` (needed for the `ruby4.0` runtime and `invoked_via_function_url` on `aws_lambda_permission`), so a newer module is possible as a follow-up.
- Add an S3 gateway endpoint (free) so S3 traffic bypasses the NAT instance. SQS goes through the NAT instance; an interface endpoint costs more than it saves.
- All four functions run in the private subnets and reuse the existing `app` security group, which RDS already allows.
- The bastion is unchanged (created only when `create_bastion` is true).

A single NAT instance is a single point of failure for sign-in and SQS publishing. Page viewing is not affected. The Auto Scaling group replaces a failed instance.

## Origin protection

CloudFront origin access control (OAC) for a Lambda Function URL requires the viewer to send the SHA-256 of the body in `x-amz-content-sha256` for POST and PUT. Ordinary HTML forms and `fetch` calls do not, so POSTs (username selection, logout, upload APIs) would fail with 403. Lambda Web Functions avoid this but support Node.js only.

Decision: the Function URL uses `AuthType NONE`. CloudFront adds a secret header to origin requests and a Rack middleware rejects requests without it.

- Terraform generates the secret (`random_password`) and passes it to the CloudFront origin and to an SSM parameter. CloudFront requires the header value in its configuration, so unlike the other secrets this one is in the Terraform state (HCP Terraform state is encrypted and access-controlled). Rotating it means replacing the `random_password` resource.
- The `app` function has a reserved concurrency limit (about 10), which bounds the cost of direct calls to the Function URL.
- The Lambda resource policy must allow public invocation of the URL. Functions created after October 2025 also need `lambda:InvokeFunction`.
- The origin request policy keeps `AllViewerExceptHostHeader`, as with the ALB today. Callback URL generation must be checked (see [Items to verify](#items-to-verify)).

## Static assets

- A dedicated bucket `pasta-atlas-production-assets` is served through the `app` distribution for `/assets/*`, using OAC and `CachingOptimized`.
- Deployment runs `aws s3 sync` of `public/assets` before the function code is updated, without `--delete`, so previous fingerprinted files remain valid during and after a rollout.
- Fingerprinted files get `Cache-Control: public, max-age=31536000, immutable`. `ftl-manifest.json` gets `max-age=300` and is invalidated on each deployment.

## Secrets

Secrets stay in SSM Parameter Store and are never written to Terraform state (see [14-secrets-management.md](14-secrets-management.md)). Unlike ECS, Lambda cannot inject SSM parameters into the environment. A small loader fetches them with `ssm:GetParameters` at initialization and sets `ENV` before Hanami reads its settings. Every entry point calls it, including the event functions and `migrate`. The execution role needs read access to the parameters under `/pasta-atlas/production/`. Initialization adds one SSM call per cold start.

Non-secret configuration is set as ordinary Lambda environment variables from Terraform.

## Asynchronous processing

- Both queues trigger their functions through event source mappings with batch size 1 and limited maximum concurrency (about 2), so database connections stay within RDS limits.
- Each queue gets a dead-letter queue with `maxReceiveCount`. Today a failing message is retried indefinitely.
- The visibility timeout is at least six times the function timeout.
- The guest cleanup schedule is not migrated. The EventBridge Scheduler resource, which targets ECS, is removed from Terraform.

## One-off tasks

Three GitHub Actions workflows run one-off ECS tasks today from the same task definition: `migrate.yml` (`hanami db migrate`), `seed.yml` (`hanami db seed`) and `delete-map.yml` (`rake maps:delete` with `MAP_ULID`). They are replaced by one `task` function that accepts an event naming an allow-listed task (`db:migrate`, `db:seed`, `maps:delete`) and runs it in-process. The maximum timeout of 15 minutes applies.

The structure dump after migration is skipped (`hanami db migrate --no-dump`). `scripts/seed-db` invokes the function instead of an ECS task.

The function is invoked with `--cli-read-timeout 0` and without CLI retries (`scripts/invoke-lambda-task`), since a retry after a client timeout would run the task, for example a migration, a second time.

## Deployment

`deploy.yml` becomes:

1. Build the zip in the Lambda base image and upload it to the artifacts bucket as `<sha>.zip` (90-day lifecycle).
2. Sync assets to S3 without `--delete`.
3. Update the code of all functions from the zip. No Lambda versions are published.
4. Invalidate `/assets/ftl-manifest.json`.

`migrate.yml`, `seed.yml` and `delete-map.yml` become manual invocations of the `task` function. Migrations run before `deploy.yml`, as today. Rolling back means re-running the code update with the zip of an earlier commit from the artifacts bucket.

## Cutover

Because the service is stopped, no parallel run or rollback stack is needed.

1. Reconcile Terraform: delete the ALB, ECS, ECR and scheduler resources from the configuration instead of recreating them. The Gandi CNAME resource stays and is redefined to target the new distribution.
2. Build the new resources (subnets, NAT instance, assets bucket, functions, DLQs, mappings, `app` distribution).
3. Apply the pending CORS change on the `mapshots` bucket (see below).
4. Run the `task` function with `db:migrate`.
5. Verify on the production domain; OAuth callbacks are already registered for it.
6. Apply the Gandi CNAME so the application domain resolves to the new distribution. Until then the domain does not resolve, which matches the current stopped state.

### CORS

The `mapshots` bucket configuration in Terraform allows `GET`, `POST` and `PUT` since commit `1e7d45f`, because presigned POST needs `POST` in the preflight. That change was never applied; the live bucket allows `PUT` only. It is applied as part of this migration.

## Local development

Local development is unchanged: Hanami runs directly, with PostgreSQL and floci in Docker.

- The local polling worker is kept for SQS, sharing `handle` with the Lambda handlers, so local runs follow the production message path.
- Guest cleanup remains a manual rake task.
- The process list in [11-local-development.md](11-local-development.md) uses `rake s3:process_queues`.

## Tooling

- `mise.toml` (`ruby = "4"`) and CI (`ruby-version: "4.0"`) are unchanged.
- `renovate.json` disables major and minor updates of `public.ecr.aws/lambda/ruby`. Changing the Ruby minor version is manual: the Terraform runtime, the tag in `scripts/build-lambda-zip` and CI change together.

## Cost estimate

| Item | Monthly (excl. tax) |
|---|---|
| RDS | about $21.5 |
| NAT instance (instance, IPv4, EBS) | about $7.5 |
| S3, CloudFront, Lambda, SQS | a few dollars at most |
| Total | about $30 |

The estimate is unmeasured. Check Cost Explorer after the migration. The RDS-managed master user secret accounts for the Secrets Manager charge.

## Items to verify

Verified locally: the Web Adapter layer with Puma on the managed `ruby:4.0` image, `pg` without system libpq, the `task` function running `db:migrate`, `db:seed` and `maps:delete` in-process, Rakefile loading, `lambda_function.rb` under Hanami boot, and the secrets loader. The account's Lambda concurrency quota is 1000, so reserved concurrency of 10 is fine. Not yet verified on real AWS:

- Hanami boot and cold start duration (including the SSM call).
- Database connectivity from the private subnets.
- OAuth callback URLs with the Function URL `Host` header.
- The current fck-nat AMI and module.

## Follow-ups

- Remove the guest cleanup: `Operations::CleanupGuestMaps`, `rake cleanup:guest_maps`, `delete_expired`, `delete_guest_orphans`, the `expire-guest` lifecycle rule and the related design notes. Guest uploads were removed in #43, and `Uploads::Create` now sets `expires_at: nil`. Before removal, confirm that no guest-owned maps or generations with `expires_at` remain in production. Dropping the `expires_at` column is a separate decision.
- Upgrade the fck-nat module (see [Networking](#networking)).
