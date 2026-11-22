# Lambda

## Overview

The application runs on AWS Lambda behind CloudFront, so no compute or load balancer is billed while it is idle. RDS and a NAT instance are the remaining fixed costs.

## Architecture

```
Viewer -> CloudFront (app)
            |- /assets/*  -> S3 (assets, OAC)
            `- default    -> Lambda Function URL (no auth, secret header)
                               `- app function (Web Adapter + Puma)
                                    |- RDS (in VPC)
                                    `- SQS, OAuth providers (via NAT instance)

SQS (s3-cleanup) -> event source mapping -> s3-cleanup function (with DLQ)
GitHub Actions -> aws lambda invoke -> task function (migrate, seed, delete map)
```

## Runtime

The managed `ruby4.0` runtime is used, deployed as a zip on arm64. The patch version is updated by AWS, so patch differences against local and CI Ruby are accepted. The AWS provider is `~> 6.45`, which the `ruby4.0` runtime and `invoked_via_function_url` on `aws_lambda_permission` require.

| Function | Trigger | Web Adapter | Memory | Timeout |
|---|---|---|---|---|
| `pasta-atlas-production-app` | CloudFront via Function URL | Yes | 1024 MB | 30 s |
| `pasta-atlas-production-task` | `aws lambda invoke` from GitHub Actions | No | 1024 MB | 900 s |
| `pasta-atlas-production-s3-cleanup` | SQS | No | 512 MB | 60 s |

All functions share one zip and one execution role (`pasta-atlas-production-app`), and write to log groups with 30-day retention. Only `app` attaches the Lambda Web Adapter layer (v30, arm64) with `AWS_LAMBDA_EXEC_WRAPPER=/opt/bootstrap`, handler `run.sh`, and Puma listening on `AWS_LWA_PORT=7000`. Port 8080 is avoided because the Lambda runtime emulator uses it; the adapter documentation also warns against 3000 and 9001. Readiness is checked at `/up` (`AWS_LWA_READINESS_CHECK_PATH`), which `OriginVerify` lets through without the secret header.

### Package

- The zip holds `vendor/bundle`, the application code, `config.ru` and `run.sh`. It is about 26 MB zipped and 69 MB unzipped, against the 250 MB limit.
- `public/assets` (about 51 MB) is served from S3. `public/` in the zip contains only the 404/500 pages and `assets/assets.json`.
- `scripts/build-lambda-zip` runs inside `public.ecr.aws/lambda/ruby:4.0` with `gcc`, `make`, `zip`, `tar` and `libyaml-devel` installed (psych builds from source), so native gems match the runtime (Amazon Linux 2023). Build artifacts (`*.o`, `*.c`, `*.h`) are removed and file modes are normalised.
- `pg` needs no system libpq: `Gemfile.lock` carries the precompiled `aarch64-linux` build, which bundles libpq.
- The runtime bootstrap adds its own gems (for example a newer `bigdecimal`) to `GEM_PATH`, so `lambda_function.rb` requires `bundler/setup` before anything else and the build fails if it does not. `run.sh` gets the same isolation from `bundle exec`. Local runtime emulator tests must set `SSM_PARAMETER_PREFIX` (local SSM in floci); otherwise the AWS SDK, which is the first code to load `bigdecimal`, is skipped and version conflicts do not show.

### Event functions

The `s3-cleanup` handler in `lambda_function.rb` passes each SQS record to `S3CleanupProcessor`, the class the local polling worker (`rake s3:process_queues`) also uses. `LambdaSupport::SqsBatch` returns only the ids of failed messages, which relies on `ReportBatchItemFailures` on the event source mapping.

## Networking

All resources stay in the default VPC. Its subnets are public, and Lambda ENIs have no public IPv4 address, so a function in them cannot reach the internet even with an internet gateway. Outbound access is needed for OAuth providers (GitHub, Discord, Steam) and SQS.

- Two private subnets (`private_subnet_cidrs`, `172.31.128.0/20` and `172.31.144.0/20` by default) in the first two availability zones. All three functions run in them with the `app` security group, which RDS allows.
- One fck-nat instance (module `RaJiska/fck-nat/aws` 1.6.1, `t4g.nano`, Auto Scaling group of one, Elastic IP) in the default subnet of the first availability zone. The private route table sends `0.0.0.0/0` to it.
- An S3 gateway endpoint (free) so S3 traffic bypasses the NAT instance. SQS goes through the NAT instance; an interface endpoint costs more than it saves.
- The bastion is created only when `create_bastion` is true.

A single NAT instance is a single point of failure for sign-in and SQS publishing. Page viewing is not affected. The Auto Scaling group replaces a failed instance.

## Origin protection

CloudFront origin access control (OAC) for a Lambda Function URL requires the viewer to send the SHA-256 of the body in `x-amz-content-sha256` for POST and PUT. Ordinary HTML forms and `fetch` calls do not, so POSTs (username selection, logout, upload APIs) would fail with 403. Lambda Web Functions avoid this but support Node.js only.

The Function URL therefore uses `AuthType NONE`. CloudFront adds the secret header `x-origin-verify` to origin requests and the `OriginVerify` Rack middleware rejects requests without it.

- Terraform generates the secret (`random_password`) and passes it to the CloudFront origin and to an SSM parameter. CloudFront requires the header value in its configuration, so unlike the other secrets this one is in the Terraform state (HCP Terraform state is encrypted and access-controlled). Rotating it means replacing the `random_password` resource.
- `config.ru` fails the boot when `SSM_PARAMETER_PREFIX` is set but `ORIGIN_VERIFY_SECRET` is missing, and the middleware raises on an empty secret.
- The `app` function has a reserved concurrency of 10 (`app_reserved_concurrency`), which bounds the cost of direct calls to the Function URL.
- The Lambda resource policy allows public invocation of the URL. Functions created after October 2025 also need `lambda:InvokeFunction`.
- The origin request policy is `AllViewerExceptHostHeader`, because the Function URL rejects the viewer `Host` header. OAuth callback URLs are built from `APP_BASE_URL`.

## Static assets

- The bucket `pasta-atlas-production-assets` is served through the `app` distribution for `/assets/*`, using OAC and `CachingOptimized`.
- Deployment runs `aws s3 sync` of `public/assets` before the function code is updated, without `--delete`, so previous fingerprinted files remain valid during and after a rollout.
- Fingerprinted files get `Cache-Control: public, max-age=31536000, immutable`. `ftl-manifest.json` gets `max-age=300` and is invalidated on each deployment.

## Secrets

Secrets are stored in SSM Parameter Store and loaded into `ENV` at initialization by every entry point, including the event functions and `task`; see [Secrets Management](secrets.md). This adds one SSM call per cold start.

Non-secret configuration is set as ordinary Lambda environment variables from Terraform.

## Asynchronous processing

- The queue triggers `s3-cleanup` through an event source mapping with batch size 1 and a maximum concurrency of 2, so database connections stay within RDS limits.
- A message moves to the dead-letter queue (`pasta-atlas-production-s3-cleanup-dlq`) after 5 receives and stays there for 14 days. A CloudWatch alarm notifies the `pasta-atlas-production-alarms` SNS topic when the DLQ is not empty; the email subscription exists only when `alarm_email` is set.
- The visibility timeout is six times the function timeout.

## One-off tasks

`migrate.yml` (`db:migrate`), `seed.yml` (`db:seed`) and `delete-map.yml` (`maps:delete`, workflow input `ulid`, event key `map_ulid`) are manual (`workflow_dispatch`) workflows that invoke the `task` function through `scripts/invoke-lambda-task`; `scripts/seed-db` does the same with `AWS_PROFILE=terraform`. The function accepts an event naming one of these allow-listed tasks and runs it in-process (`lib/lambda_support/task_runner.rb`); the fourth to sixth, `cleanup:stale_uploads`, `cleanup:orphaned_avatars` and `cleanup:orphaned_maps`, are run by the schedules below. `cleanup:orphaned_maps` only lists the S3 prefixes of maps missing from the database unless the event sets `"dry_run": false`, so a manual invocation without it is a dry run. The 15-minute maximum timeout applies. The structure dump after migration is skipped because the image has no `pg_dump`.

The function is invoked with `--cli-read-timeout 0` and without CLI retries, since a retry after a client timeout would run the task, for example a migration, a second time.

## Scheduled cleanup

EventBridge Scheduler invokes the `task` function every day at 03:00 JST with `{"task": "cleanup:stale_uploads"}` (`scheduler.tf`; the schedule's role may only invoke that function). The selection rules of `Operations::Uploads::CleanupStale` are in [Upload Flow](../architecture/upload-flow.md#stale-upload-cleanup). The task exits with an error when a prefix cannot be queued. The schedule does not retry; the next day's run is the retry.

At 03:30 JST the same function runs `{"task": "cleanup:orphaned_avatars"}`. `Operations::CleanupOrphanedAvatars` deletes the objects under `{user_name}/avatar/` that the user's profile does not refer to and that are more than a day old; the grace period covers an avatar uploaded just before the profile is updated. Prefixes of users missing from the database are skipped. The task exits with an error on an S3 failure, and the next day's run is the retry.

At 04:00 JST the same function runs `{"task": "cleanup:orphaned_maps", "dry_run": false}`. `Operations::CleanupOrphanedMaps` deletes the `{user_name}/maps/{map_id}/` prefixes that have no map record. A map record is created before any object under its prefix is written, so an upload in progress is not affected. Prefixes of users missing from the database are skipped. The task exits with an error on an S3 failure, and the next day's run is the retry.

## Deployment

`deploy.yml` is run manually on `ubuntu-24.04-arm`. It:

1. Compiles the assets and builds the zip in the Lambda base image, then uploads it to `pasta-atlas-production-lambda-artifacts` as `<sha>.zip` (90-day lifecycle).
2. Syncs assets to `pasta-atlas-production-assets/assets/` without `--delete`, and uploads `ftl-manifest.json` with `max-age=300`.
3. Updates the code of all three functions from the zip, waiting for each update to finish. No Lambda versions are published.
4. Invalidates `/assets/ftl-manifest.json` on the distribution that carries the application domain.

Run `deploy.yml` first and then `migrate.yml`, because only `deploy.yml` updates the code of the `task` function. Migrations must be backward compatible with the previously deployed application code, since the new code runs briefly before the schema change. After dropping or renaming a column, deploy again: warm environments cache the ROM-inferred schema. Rolling back means re-running the code update with the zip of an earlier commit from the artifacts bucket.

## Local development

Hanami runs directly, with PostgreSQL and floci in Docker. The local polling worker (`rake s3:process_queues`) shares `S3CleanupProcessor` with the Lambda handler, so local runs follow the production message path. See [Local Setup](../development/local-setup.md).

## Tooling

`.github/renovate.json` disables major and minor updates of `public.ecr.aws/lambda/ruby`. Changing the Ruby minor version is manual: the Terraform runtime, the tag in `scripts/build-lambda-zip` and CI change together.
