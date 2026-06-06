# Infrastructure

## Overview

pasta_atlas runs on AWS with container-based deployment. DNS is managed by Gandi.

## AWS Services

| Service | Role |
|---|---|
| ECS Fargate | Application runtime (no EC2 to manage) |
| ECR | Docker image registry |
| ALB | HTTPS termination, Gandi CNAME target |
| ACM | TLS certificate for ALB and CloudFront |
| RDS (PostgreSQL) | Database |
| S3 | Tile image and mapshot.json storage |
| CloudFront | CDN for S3 content and static assets |
| SQS | Async queue for S3 object deletion requests |
| VPC | Network isolation; RDS in private subnet |
| SSM Parameter Store | Runtime secrets (SecureString) |
| CloudWatch Logs | Application logs (30-day retention) |
| IAM | ECS task role (S3/SQS/SSM access), deploy role (CI/CD) |

ACM certificates for CloudFront must be provisioned in us-east-1 (AWS requirement). The ALB certificate is provisioned in the primary region (ap-northeast-1).

## Domains

| Environment | Application (ALB) | Assets (CloudFront) |
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

Gandi manages DNS. No Route 53 is used. The application domain CNAME points to the ALB DNS name; the CDN domain CNAME points to the CloudFront distribution.

## Container Deployment

The application runs as an ECS Service backed by Fargate. Each deployment follows this sequence:

1. GitHub Actions builds a Docker image and pushes it to ECR
2. GitHub Actions updates the ECS Service to trigger a rolling deployment
3. ECS replaces old tasks with new ones; GitHub Actions waits for stability
4. GitHub Actions invalidates the CloudFront cache for `/assets/ftl-manifest.json`

Database migrations run as a one-off ECS task using the same image, executed before the service update.

## CI/CD Workflows

| Workflow | Trigger | Purpose |
|---|---|---|
| `ci.yml` | Push to `main`, pull requests | Runs tests and linters |
| `deploy.yml` | Manual (`workflow_dispatch`) | Builds and deploys to production |
| `migrate.yml` | Manual (`workflow_dispatch`) | Runs DB migrations in production |

### ci.yml

Two parallel jobs:

- **backend**: spins up PostgreSQL, compiles frontend assets, loads DB structure, then runs `bundle exec rake` (RuboCop + RSpec)
- **frontend**: runs `npm run type-check`, `npm run lint:frontend`, and `npm run test:frontend`

### deploy.yml

Two sequential jobs:

1. **build**: builds a multi-arch Docker image (`linux/arm64`), pushes to ECR with `:latest` and `:<git-sha>` tags; uses GitHub Actions cache for layer caching
2. **deploy**: triggers force-new-deployment on both ECS services (`pasta-atlas-production` and `pasta-atlas-production-s3-cleanup-queue-worker`), waits for stability, then invalidates the CloudFront `/assets/ftl-manifest.json` cache entry

### migrate.yml

Runs `bundle exec hanami db migrate` as a Fargate one-off task using the `pasta-atlas-production-migrate` task definition. The workflow retrieves network configuration from the running service, launches the task, waits for it to stop, and checks its exit code.

## Database Migrations

The migrate task definition reuses the same Docker image as the application, overriding the command to `bundle exec hanami db migrate`.

**Initial schema setup** (e.g., bootstrapping a new environment):

```bash
# Run as a one-off ECS task or locally against the target database
bundle exec hanami db structure load
```

**Ongoing migrations** (each deploy that includes schema changes):

1. Trigger `migrate.yml` via GitHub Actions
2. The workflow launches the ECS migrate task and waits for it to exit cleanly
3. Trigger `deploy.yml` to roll out the new application image

## S3 Bucket Policy

The mapshots bucket is fully private (all public access blocked). CloudFront accesses it via Origin Access Control (OAC) with SigV4 signing. The bucket policy grants `s3:GetObject` only to the mapshots CloudFront distribution:

```
Principal: cloudfront.amazonaws.com
Condition: AWS:SourceArn == <mapshots distribution ARN>
```

The application ECS task role holds `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject`, and `s3:ListBucket` for generating presigned URLs and managing objects.

The S3 lifecycle rule that expires objects under the `guest/maps/` prefix after 8 days can be removed once any existing guest data has naturally expired.

CORS is configured for `PUT` requests from allowed origins (for presigned URL uploads), exposing the `ETag` header.

## CloudFront Distributions

Two distributions are provisioned:

### `app` — application domain (`pasta-atlas.layer8.works`)

| Path | Origin | Cache policy |
|---|---|---|
| `/assets/*` | ALB | CachingOptimized (long TTL) |
| `*` (default) | ALB | CachingDisabled + AllViewerExceptHostHeader |

Static assets are safe to cache long-term because Vite fingerprints filenames with a content hash. Dynamic responses are not cached.

### `mapshots` — CDN domain (`maps.pasta-atlas.layer8.works`)

Single origin: S3 bucket via OAC. All requests use CachingOptimized. A CORS response headers policy adds `Access-Control-Allow-Origin` for allowed origins.

## Terraform

Infrastructure is managed under `terraform/environments/`.

- `production/` is the production root and directly declares the AWS resources used by the application.
- `local/` contains the local mapshots S3 support used during development.

Terraform manages all infrastructure except ECS Task Definition revisions, which are updated by CI/CD on each deployment.

## Environments

| Environment | Managed by |
|---|---|
| production | Terraform + GitHub Actions |
| development | Local (Hanami dev server + local PostgreSQL) |

No staging environment is defined at this time.

### Local development

See [11-local-development.md](11-local-development.md).
