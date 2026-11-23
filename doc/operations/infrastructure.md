# Infrastructure

## Overview

Pasta Atlas runs on AWS Lambda behind CloudFront. DNS is managed by Gandi. The runtime design, networking, origin protection and deployment are described in [Lambda](lambda.md); this document covers the rest.

## AWS Services

| Service | Role |
|---|---|
| Lambda | Application (`app`), one-off tasks (`task`) and SQS workers |
| CloudFront | `app` distribution (application and static assets) and `mapshots` distribution (CDN for tiles) |
| ACM | TLS certificates for the CloudFront distributions |
| RDS (PostgreSQL) | Database |
| S3 | Tile images and mapshot.json (`mapshots`), static assets (`assets`), deploy packages (`artifacts`) |
| SQS | Async queue for S3 object deletion, with a dead-letter queue |
| VPC | Default VPC shared by RDS and Lambda; Lambda runs in added private subnets with a NAT instance (fck-nat) for outbound access |
| SSM Parameter Store | Runtime secrets (SecureString) |
| CloudWatch Logs | Application logs |
| CloudWatch Alarms | Alarm on messages in the s3-cleanup dead-letter queue, notified through an SNS topic |
| IAM | One execution role shared by the three functions (VPC access, S3, SQS, SSM and `kms:Decrypt`); the `github-actions-cicd` OIDC role for the workflows, assumable only from the `main` branch |

ACM certificates for CloudFront must be provisioned in us-east-1 (AWS requirement).

## Domains

| Environment | Application (`app` distribution) | Tiles (`mapshots` distribution) |
|---|---|---|
| production | `pasta-atlas.layer8.works` | `maps.pasta-atlas.layer8.works` |

## S3 Buckets

| Environment | Bucket | Contents |
|---|---|---|
| production | `pasta-atlas-production-mapshots` | Tile images, mapshot.json and avatars |
| production | `pasta-atlas-production-assets` | Fingerprinted static assets |
| production | `pasta-atlas-production-lambda-artifacts` | Deploy packages (90-day expiry) |
| local | `pasta-atlas-local-mapshots` | Everything, in floci |

The key layout is described in [Upload Flow](../architecture/upload-flow.md#s3-key-structure).

## DNS

Gandi manages DNS (TTL 300); Route 53 is not used. The CNAMEs for the application and tiles domains point to their CloudFront distributions (the application record is controlled by `app_dns_enabled`), and the ACM validation records are created in Gandi too.

## Deployment and CI/CD

| Workflow | Trigger | Purpose |
|---|---|---|
| `ci.yml` | Push to `main`, pull requests | Runs tests and linters |
| `deploy.yml` | Manual (`workflow_dispatch`) | Builds the Lambda package and deploys to production |
| `migrate.yml` | Manual (`workflow_dispatch`) | Runs DB migrations through the `task` function |
| `seed.yml` | Manual (`workflow_dispatch`) | Runs DB seed through the `task` function |
| `delete-map.yml` | Manual (`workflow_dispatch`) | Deletes a map through the `task` function |

The jobs of `ci.yml` are described in [Code Quality](../development/code-quality.md#ci).

The deploy sequence, rollback and one-off task invocation are described in [Lambda](lambda.md#deployment). When a release contains migrations, run `migrate.yml` after `deploy.yml`.

## S3 Bucket Policy

The mapshots bucket is fully private (all public access blocked). CloudFront accesses it via Origin Access Control (OAC) with SigV4 signing. The bucket policy grants `s3:GetObject` only to the mapshots CloudFront distribution:

```
Principal: cloudfront.amazonaws.com
Condition: AWS:SourceArn == <mapshots distribution ARN>
```

The Lambda execution role holds `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`, and `s3:ListBucket` for generating presigned URLs and managing objects.

CORS allows `POST` from `allowed_origins` (presigned uploads) and exposes the `ETag` header.

## CloudFront Distributions

Two distributions are provisioned:

### `app` — application domain (`pasta-atlas.layer8.works`)

| Path | Origin | Cache policy |
|---|---|---|
| `/assets/*` | S3 `assets` bucket (OAC) | CachingOptimized (long TTL) |
| `*` (default) | Lambda Function URL | CachingDisabled + AllViewerExceptHostHeader |

Static assets are safe to cache long-term because Vite fingerprints filenames with a content hash. Dynamic responses are not cached. See [Lambda](lambda.md#origin-protection) for how the Function URL is protected.

The default behavior runs the `maintenance` CloudFront Function on viewer requests; see [Maintenance Mode](maintenance.md).

### `mapshots` — CDN domain (`maps.pasta-atlas.layer8.works`)

Single origin: S3 bucket via OAC. All requests use CachingOptimized. A CORS response headers policy adds `Access-Control-Allow-Origin` for allowed origins.

## RDS

PostgreSQL 18 on `db.t4g.micro` (20 GB, single AZ, 7-day backups, deletion protection). The master password is managed by Secrets Manager. The security group accepts port 5432 only from the `app` security group used by the functions. A bastion instance exists only when `create_bastion` is true.

## Terraform

Infrastructure is managed under `terraform/environments/`.

- `production/` is the production root and directly declares the AWS resources used by the application.
- `local/` creates the S3 bucket and the SQS queue used during development.

Terraform manages all infrastructure. Function code is updated by CI/CD on each deployment.

## Environments

| Environment | Managed by |
|---|---|
| production | Terraform + GitHub Actions |
| local | Hanami dev server, PostgreSQL and floci in Docker; S3 and SQS created by `terraform/environments/local` |

No staging environment is defined at this time.

### Local development

See [Local Setup](../development/local-setup.md).
