# Terraform — PastaAtlas Infrastructure

## Structure

```
pasta-atlas/
  environments/
    production/   # production infrastructure root
    local/        # S3 and SQS only — web app runs locally
```

### environments/production

| File | Description |
|---|---|
| `main.tf` | Terraform backend and providers |
| `variables.tf` | Production configuration inputs |
| `s3.tf` | S3 bucket for map assets |
| `cloudfront.tf` | CloudFront distributions |
| `acm.tf` | ACM certificates |
| `dns.tf` | DNS records |
| `alb.tf` | Application Load Balancer |
| `ecs.tf` | ECS cluster, task definitions, and services |
| `rds.tf` | RDS PostgreSQL instance |
| `iam.tf` | IAM roles and policies |
| `ssm.tf` | SSM parameters (secrets) |
| `sqs.tf` | SQS queue for S3 cleanup |
| `scheduler.tf` | EventBridge scheduler |
| `outputs.tf` | `ecr_repository_url`, `rds_endpoint`, and other outputs |

## Before First Use

### 1. Initialize and apply

No `terraform.tfvars` is required; all variables have defaults.

```bash
cd environments/production   # or local
terraform init
terraform plan
terraform apply
```

### 2. Set secrets in SSM (production only)

After the first apply, set the actual values:

```bash
aws ssm put-parameter \
  --name /pasta-atlas/production/session_secret \
  --value "$(openssl rand -hex 64)" \
  --type SecureString \
  --overwrite

aws ssm put-parameter \
  --name /pasta-atlas/production/github_client_secret \
  --value "YOUR_GITHUB_CLIENT_SECRET" \
  --type SecureString \
  --overwrite

aws ssm put-parameter \
  --name /pasta-atlas/production/discord_client_secret \
  --value "YOUR_DISCORD_CLIENT_SECRET" \
  --type SecureString \
  --overwrite

aws ssm put-parameter \
  --name /pasta-atlas/production/steam_web_api_key \
  --value "YOUR_STEAM_WEB_API_KEY" \
  --type SecureString \
  --overwrite

# Retrieve the RDS master password from AWS Secrets Manager first
aws ssm put-parameter \
  --name /pasta-atlas/production/database_url \
  --value "postgres://pasta_atlas:<pass>@<rds_endpoint>/pasta_atlas" \
  --type SecureString \
  --overwrite
```

The RDS master password is managed automatically by AWS Secrets Manager (`manage_master_user_password = true`).

## Deploying a New Application Version

```bash
# Build and push image
docker build -t pasta-atlas .
docker tag pasta-atlas:latest <ecr_repository_url>:latest
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin <ecr_repository_url>
docker push <ecr_repository_url>:latest

# Force ECS to pull the new image
aws ecs update-service \
  --cluster pasta-atlas-production \
  --service pasta-atlas-production \
  --force-new-deployment
```

## Application Environment Variables

ECS task definitions wire env vars automatically. The table below lists the source for each variable.

### Production

| App env var | Source |
|---|---|
| `S3_BUCKET` | `s3_bucket_name` output |
| `CLOUDFRONT_BASE_URL` | `cloudfront_domain_name` output |
| `SQS_S3_CLEANUP_QUEUE_URL` | `sqs_s3_cleanup_queue_url` output |
| `SESSION_SECRET` | SSM: `/pasta-atlas/production/session_secret` |
| `GITHUB_CLIENT_SECRET` | SSM: `/pasta-atlas/production/github_client_secret` |
| `DISCORD_CLIENT_SECRET` | SSM: `/pasta-atlas/production/discord_client_secret` |
| `STEAM_WEB_API_KEY` | SSM: `/pasta-atlas/production/steam_web_api_key` |
| `DATABASE_URL` | SSM: `/pasta-atlas/production/database_url` |

### Local (from `terraform output`)

| Output | App env var |
|---|---|
| `s3_bucket_name` | `S3_BUCKET` |
| `sqs_s3_cleanup_queue_url` | `SQS_S3_CLEANUP_QUEUE_URL` |

Database and session secret are managed locally in the local environment.
