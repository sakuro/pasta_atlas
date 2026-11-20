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
| `main.tf` | HCP Terraform backend and providers |
| `variables.tf` | Production configuration inputs |
| `s3.tf` | S3 bucket for map assets |
| `cloudfront.tf` | CloudFront distributions |
| `acm.tf` | ACM certificates |
| `dns.tf` | DNS records |
| `network.tf` | Private subnets, fck-nat, S3 endpoint |
| `assets.tf` | Assets bucket |
| `lambda.tf` | Lambda functions, Function URL, event source mappings |
| `lambda_support.tf` | Origin secret, artifacts bucket, log groups |
| `rds.tf` | RDS PostgreSQL instance |
| `iam.tf` | IAM roles and policies |
| `ci_role.tf` | GitHub Actions OIDC role and its policies |
| `alarms.tf` | SNS topic and CloudWatch alarm for the dead-letter queue (set `alarm_email` to subscribe) |
| `ssm.tf` | SSM parameters (secrets) |
| `sqs.tf` | SQS queue for S3 cleanup |
| `outputs.tf` | `rds_endpoint`, bucket and CloudFront outputs |

## State

The production state is stored in the `pasta-atlas-production` workspace of the `sakuro` organization on HCP Terraform (execution mode: Local, so plans and applies run on this machine). `environments/local` uses local state.

HCP Terraform authenticates with a team API token (organization tokens cannot lock or write state). Store it in the global fnox configuration as `TF_TOKEN_app_terraform_io`; the `fnox-env` plugin in `mise.toml` exports it.

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

Deployment is done by the GitHub Actions deploy workflow, which uploads the Lambda package to the `lambda_artifacts_bucket`, the compiled assets to the `assets_bucket`, and invalidates the `app_cloudfront_distribution_id` distribution.

## Application Environment Variables

The Lambda functions receive env vars from `lambda.tf`; secrets are fetched from SSM at init. The table below lists the source for each variable.

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
