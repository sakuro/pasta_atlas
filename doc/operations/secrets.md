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

## Loading

Lambda cannot inject SSM parameters into the environment. `LambdaSupport::SecretsLoader` (`lib/lambda_support/secrets_loader.rb`) fetches them with `ssm:GetParameters` under the prefix given by `SSM_PARAMETER_PREFIX` and sets `ENV` before Hanami reads its settings. Every Lambda entry point calls it during initialization, so a secret update takes effect on the next cold start. The execution role needs `ssm:GetParameters` on the prefix and `kms:Decrypt`.

`origin_verify_secret` is the exception to the storage rule above: Terraform generates it (`random_password`) because CloudFront needs the value in its origin configuration, so it is stored in the Terraform state. See [Lambda](lambda.md#origin-protection).
