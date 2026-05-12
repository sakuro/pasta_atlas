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
| CloudFront | CDN for S3 content |
| VPC | Network isolation; RDS in private subnet |
| Secrets Manager | Runtime secrets (SESSION_SECRET, DATABASE_URL) |
| CloudWatch Logs | Application and ALB logs |
| IAM | ECS task role (S3 access), deploy role (CI/CD) |

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

Guest uploads use `guest` as the user profile name prefix, enabling S3 lifecycle rules to expire guest data automatically.

## DNS

Gandi manages DNS. No Route 53 is used. The application domain CNAME points to the ALB DNS name; the CDN domain CNAME points to the CloudFront distribution.

## Container Deployment

The application runs as an ECS Service backed by Fargate. Each deployment follows this sequence:

1. GitHub Actions builds a Docker image and pushes it to ECR
2. GitHub Actions registers a new ECS Task Definition revision with the new image
3. GitHub Actions updates the ECS Service to use the new revision
4. ECS performs a rolling deployment (old tasks replaced by new ones)

Database migrations run as a one-off ECS task using the same image, executed before the service update.

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
