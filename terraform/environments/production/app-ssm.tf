# SESSION_SECRET is stored here and read by the app at startup.
# Set the actual value with:
#   aws ssm put-parameter --name /pasta-atlas/production/session_secret \
#     --value "$(openssl rand -hex 64)" --type SecureString --overwrite
resource "aws_ssm_parameter" "session_secret" {
  name  = "/${var.app_name}/${var.environment}/session_secret"
  type  = "SecureString"
  value = "REPLACE_WITH_SECURE_RANDOM_VALUE"

  lifecycle {
    ignore_changes = [value]
  }
}
