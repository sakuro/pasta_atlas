# Terraform — PastaAtlas Infrastructure

## Structure

```
pasta-atlas/
  environments/
    production/   # production infrastructure root
    local/        # mapshots only — web app runs locally
```

### environments/production

| File | Description |
|---|---|
| `main.tf` | Terraform backend and providers |
| `variables.tf` | Production configuration inputs |
| `mapshots-*.tf` | S3, CloudFront, ACM, and DNS for uploaded map assets |
| `app-*.tf` | ECS, ALB, CloudFront, RDS, IAM, scheduler, DNS, and SSM |
| `outputs.tf` | `ecr_repository_url`, `rds_endpoint`, `session_secret_ssm_path` |

## Before First Use

### 1. Create `terraform.tfvars` (production only)

Local has no required variables. Production requires the database password:

```
db_password = "your-secure-password"
```

### 2. Initialize and apply

```bash
cd environments/production   # or local
terraform init
scripts/tf plan
scripts/tf apply
```

### 3. Set the session secret (production only)

After the first apply, set the actual value in SSM:

```bash
aws ssm put-parameter \
  --name /pasta-atlas/production/session_secret \
  --value "$(openssl rand -hex 64)" \
  --type SecureString \
  --overwrite
```

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

### Production (from `terraform output`)

| Output | App env var |
|---|---|
| `s3_bucket_name` | `S3_BUCKET` |
| `cloudfront_domain_name` | `CLOUDFRONT_BASE_URL` |
| `rds_endpoint` | `DATABASE_URL` (format: `postgres://pasta_atlas:<pass>@<endpoint>/pasta_atlas`) |
| `session_secret_ssm_path` | — fetch at startup via SSM |

### Local (from `terraform output`)

| Output | App env var |
|---|---|
| `s3_bucket_name` | `S3_BUCKET` |

Database and session secret are managed locally in the local environment.
