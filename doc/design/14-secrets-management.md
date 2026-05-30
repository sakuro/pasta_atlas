# Secrets Management

## Secret Values

| Value | Classification |
|---|---|
| `DATABASE_URL` | Secret |
| `SESSION_SECRET` | Secret |
| `GITHUB_CLIENT_SECRET` | Secret |
| `DISCORD_CLIENT_SECRET` | Secret |
| `STEAM_WEB_API_KEY` | Secret |
| `GITHUB_CLIENT_ID` | Non-secret configuration |
| `DISCORD_CLIENT_ID` | Non-secret configuration |

`GITHUB_CLIENT_ID` and `DISCORD_CLIENT_ID` are public OAuth application identifiers and are passed as plain environment variables.

## Storage

All secrets are stored as `SecureString` parameters in AWS SSM Parameter Store under the path `/{app_name}/{environment}/{name}`.

Terraform creates the parameter resources with a placeholder value (`REPLACE_WITH_ACTUAL_VALUE`) and `ignore_changes = [value]`, so actual secret values are set manually via the AWS CLI and are never written into Terraform state:

```bash
aws ssm put-parameter --overwrite \
  --name "/pasta-atlas/production/session_secret" \
  --type SecureString \
  --value "<actual value>"
```

## ECS Injection

Secrets are injected into ECS tasks at launch via the `secrets` field in the task definition, referencing SSM parameter ARNs:

```json
{ "name": "SESSION_SECRET", "valueFrom": "<ssm-parameter-arn>" }
```

The ECS execution role holds `ssm:GetParameter`, `ssm:GetParameters`, and `kms:Decrypt` (via KMS service condition) to read the SecureString values at task start. A secret update takes effect only after a new task is launched (force-new-deployment or next scheduled task start).
