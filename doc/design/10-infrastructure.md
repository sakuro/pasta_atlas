# Infrastructure

## Overview

pasta_atlas runs on AWS Lambda behind CloudFront. DNS is managed by Gandi. The runtime design, networking, origin protection and deployment are described in [16-lambda-migration.md](16-lambda-migration.md); this document covers the rest.

## AWS Services

| Service | Role |
|---|---|
| Lambda | Application (`app`), one-off tasks (`task`) and SQS workers |
| CloudFront | `app` distribution (application and static assets) and `mapshots` distribution (CDN for tiles) |
| ACM | TLS certificates for the CloudFront distributions |
| RDS (PostgreSQL) | Database |
| S3 | Tile images and mapshot.json (`mapshots`), static assets (`assets`), deploy packages (`artifacts`) |
| SQS | Async queues for S3 object deletion and storage calculation, each with a dead-letter queue |
| VPC | Default VPC shared by RDS and Lambda; Lambda runs in added private subnets with a NAT instance (fck-nat) for outbound access |
| SSM Parameter Store | Runtime secrets (SecureString) |
| CloudWatch Logs | Application logs |
| IAM | Function execution roles (S3/SQS/SSM access), deploy role (CI/CD) |

ACM certificates for CloudFront must be provisioned in us-east-1 (AWS requirement).

## Domains

| Environment | Application (`app` distribution) | Tiles (`mapshots` distribution) |
|---|---|---|
| production | `pasta-atlas.layer8.works` | `maps.pasta-atlas.layer8.works` |
| development | `pasta-atlas-development.layer8.works` | `maps.pasta-atlas-development.layer8.works` |

## S3 Buckets

| Environment | Bucket |
|---|---|
| production | `pasta-atlas-production-mapshots` |
| development | `pasta-atlas-development-mapshots` |

### Key structure

```
{user_profile_name}/{mapshot_map_id}/{mapshot_unique_id}/{filename}
```

## DNS

Gandi manages DNS. No Route 53 is used. Both CNAMEs point to their CloudFront distributions.

## Deployment and CI/CD

| Workflow | Trigger | Purpose |
|---|---|---|
| `ci.yml` | Push to `main`, pull requests | Runs tests and linters |
| `deploy.yml` | Manual (`workflow_dispatch`) | Builds the Lambda package and deploys to production |
| `migrate.yml` | Manual (`workflow_dispatch`) | Runs DB migrations through the `task` function |
| `seed.yml` | Manual (`workflow_dispatch`) | Runs DB seed through the `task` function |
| `delete-map.yml` | Manual (`workflow_dispatch`) | Deletes a map through the `task` function |

`ci.yml` runs two parallel jobs:

- **backend**: spins up PostgreSQL, compiles frontend assets, loads DB structure, then runs `bundle exec rake` (RuboCop + RSpec)
- **frontend**: runs `npm run type-check`, `npm run lint:frontend`, and `npm run test:frontend`

The deploy sequence, rollback and one-off task invocation are described in [16-lambda-migration.md](16-lambda-migration.md#deployment). Run `migrate.yml` before `deploy.yml` when a release contains migrations.

## S3 Bucket Policy

The mapshots bucket is fully private (all public access blocked). CloudFront accesses it via Origin Access Control (OAC) with SigV4 signing. The bucket policy grants `s3:GetObject` only to the mapshots CloudFront distribution:

```
Principal: cloudfront.amazonaws.com
Condition: AWS:SourceArn == <mapshots distribution ARN>
```

The `app` function's execution role holds `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`, and `s3:ListBucket` for generating presigned URLs and managing objects.

The S3 lifecycle rule that expires objects under the `guest/maps/` prefix after 8 days can be removed once any existing guest data has naturally expired.

CORS is configured for `PUT` requests from allowed origins (for presigned URL uploads), exposing the `ETag` header.

## CloudFront Distributions

Two distributions are provisioned:

### `app` — application domain (`pasta-atlas.layer8.works`)

| Path | Origin | Cache policy |
|---|---|---|
| `/assets/*` | S3 `assets` bucket (OAC) | CachingOptimized (long TTL) |
| `*` (default) | Lambda Function URL | CachingDisabled + AllViewerExceptHostHeader |

Static assets are safe to cache long-term because Vite fingerprints filenames with a content hash. Dynamic responses are not cached. See [16-lambda-migration.md](16-lambda-migration.md#origin-protection) for how the Function URL is protected.

### `mapshots` — CDN domain (`maps.pasta-atlas.layer8.works`)

Single origin: S3 bucket via OAC. All requests use CachingOptimized. A CORS response headers policy adds `Access-Control-Allow-Origin` for allowed origins.

## Terraform

Infrastructure is managed under `terraform/environments/`.

- `production/` is the production root and directly declares the AWS resources used by the application.
- `local/` contains the local mapshots S3 support used during development.

Terraform manages all infrastructure. Function code is updated by CI/CD on each deployment.

## Environments

| Environment | Managed by |
|---|---|
| production | Terraform + GitHub Actions |
| development | Local (Hanami dev server + local PostgreSQL) |

No staging environment is defined at this time.

### Local development

See [11-local-development.md](11-local-development.md).
