# Terraform — PastaAtlas Infrastructure

## Structure

```
pasta-atlas/
  module/
    mapshots/     # S3 + CloudFront for map image storage and delivery
    backend/      # ECS Fargate, ALB, RDS, ECR, IAM, SSM (production only)
  environments/
    production/   # pasta-atlas.layer8.works
    local/        # mapshots only — web app runs locally
```

### module/mapshots

| File | Description |
|---|---|
| `versions.tf` | Provider requirements (`aws.us_east_1` alias for CloudFront ACM) |
| `variables.tf` | `app_name`, `environment`, `maps_domain_name`, `allowed_origins`, etc. |
| `s3.tf` | S3 bucket with CORS for presigned URL uploads |
| `cloudfront.tf` | CloudFront distribution serving S3 via OAC |
| `acm.tf` | ACM certificate in us-east-1 with DNS validation |
| `dns.tf` | CNAME on layer8.works → CloudFront |
| `outputs.tf` | `s3_bucket_name`, `s3_bucket_arn`, `cloudfront_domain_name`, `cloudfront_distribution_id` |

### module/backend

| File | Description |
|---|---|
| `versions.tf` | Provider requirements |
| `variables.tf` | App domain, S3/CloudFront refs (from mapshots), DB and ECS settings |
| `ecs.tf` | ECR repository, ECS cluster, Fargate task and service |
| `alb.tf` | ALB, HTTP/HTTPS listeners, target group, and security groups |
| `acm.tf` | ACM certificate in ap-northeast-1 for ALB |
| `dns.tf` | CNAME on layer8.works → CloudFront |
| `rds.tf` | RDS PostgreSQL (default VPC, `deletion_protection = true`) |
| `iam.tf` | Fargate task role with S3 and SSM access |
| `ssm.tf` | SSM Parameter Store entry for `SESSION_SECRET` |
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
