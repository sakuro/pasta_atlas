resource "aws_ecs_task_definition" "migrate" {
  family                   = "${var.app_name}-${var.environment}-migrate"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  task_role_arn            = aws_iam_role.app.arn
  execution_role_arn       = aws_iam_role.execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name    = var.app_name
      image   = local.container_image
      command = ["bundle", "exec", "hanami", "db", "migrate"]
      environment = [
        { name = "HANAMI_ENV", value = var.environment },
        { name = "AWS_REGION", value = var.aws_region },
        { name = "APP_BASE_URL", value = "https://${var.app_domain_name}" },
        { name = "S3_BUCKET", value = aws_s3_bucket.mapshots.bucket },
        { name = "CLOUDFRONT_BASE_URL", value = "https://${aws_cloudfront_distribution.mapshots.domain_name}" },
        { name = "SQS_S3_CLEANUP_QUEUE_URL", value = aws_sqs_queue.s3_cleanup.url },
        { name = "PRESIGNED_URL_EXPIRY", value = tostring(var.presigned_url_expiry) },
        { name = "GITHUB_CLIENT_ID", value = var.github_client_id },
        { name = "DISCORD_CLIENT_ID", value = var.discord_client_id },
      ]
      secrets = [
        { name = "SESSION_SECRET", valueFrom = aws_ssm_parameter.session_secret.arn },
        { name = "GITHUB_CLIENT_SECRET", valueFrom = aws_ssm_parameter.github_client_secret.arn },
        { name = "DISCORD_CLIENT_SECRET", valueFrom = aws_ssm_parameter.discord_client_secret.arn },
        { name = "STEAM_WEB_API_KEY", valueFrom = aws_ssm_parameter.steam_web_api_key.arn },
        { name = "DATABASE_URL", valueFrom = aws_ssm_parameter.database_url.arn },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "migrate"
        }
      }
    }
  ])
}
