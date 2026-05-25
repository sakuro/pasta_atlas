# Set actual values with aws ssm put-parameter --overwrite after creation.

resource "aws_ssm_parameter" "session_secret" {
  name  = "/${var.app_name}/${var.environment}/session_secret"
  type  = "SecureString"
  value = "REPLACE_WITH_ACTUAL_VALUE"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "github_client_secret" {
  name  = "/${var.app_name}/${var.environment}/github_client_secret"
  type  = "SecureString"
  value = "REPLACE_WITH_ACTUAL_VALUE"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "discord_client_secret" {
  name  = "/${var.app_name}/${var.environment}/discord_client_secret"
  type  = "SecureString"
  value = "REPLACE_WITH_ACTUAL_VALUE"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "steam_web_api_key" {
  name  = "/${var.app_name}/${var.environment}/steam_web_api_key"
  type  = "SecureString"
  value = "REPLACE_WITH_ACTUAL_VALUE"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "database_url" {
  name  = "/${var.app_name}/${var.environment}/database_url"
  type  = "SecureString"
  value = "REPLACE_WITH_ACTUAL_VALUE"

  lifecycle {
    ignore_changes = [value]
  }
}
