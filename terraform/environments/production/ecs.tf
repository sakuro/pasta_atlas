resource "aws_ecr_repository" "app" {
  name                 = "${var.app_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = { type = "expire" }
      }
    ]
  })
}

locals {
  container_image = "${aws_ecr_repository.app.repository_url}:latest"
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.app_name}-${var.environment}"
  retention_in_days = 30
}

# ECS agent uses this role to pull images from ECR and write logs to CloudWatch
resource "aws_iam_role" "execution" {
  name = "${var.app_name}-${var.environment}-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-${var.environment}"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  task_role_arn            = aws_iam_role.app.arn
  execution_role_arn       = aws_iam_role.execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name  = var.app_name
      image = local.container_image
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "HANAMI_ENV", value = var.environment },
        { name = "AWS_REGION", value = var.aws_region },
        { name = "HANAMI_SERVE_ASSETS", value = "true" },
        { name = "APP_BASE_URL", value = "https://${var.app_domain_name}" },
        { name = "S3_BUCKET", value = aws_s3_bucket.mapshots.bucket },
        { name = "CLOUDFRONT_BASE_URL", value = "https://${aws_cloudfront_distribution.mapshots.domain_name}" },
        { name = "SQS_S3_CLEANUP_QUEUE_URL", value = aws_sqs_queue.s3_cleanup.url },
        { name = "SQS_STORAGE_CALCULATION_QUEUE_URL", value = aws_sqs_queue.storage_calculation.url },
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
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "${var.app_name}-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.https]
}

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
        { name = "SQS_STORAGE_CALCULATION_QUEUE_URL", value = aws_sqs_queue.storage_calculation.url },
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

resource "aws_ecs_task_definition" "s3_cleanup_queue_worker" {
  family                   = "${var.app_name}-${var.environment}-s3-queue-worker"
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
      name        = var.app_name
      image       = local.container_image
      command     = ["bundle", "exec", "rake", "s3:process_queues"]
      stopTimeout = 60
      environment = [
        { name = "HANAMI_ENV", value = var.environment },
        { name = "AWS_REGION", value = var.aws_region },
        { name = "APP_BASE_URL", value = "https://${var.app_domain_name}" },
        { name = "S3_BUCKET", value = aws_s3_bucket.mapshots.bucket },
        { name = "CLOUDFRONT_BASE_URL", value = "https://${aws_cloudfront_distribution.mapshots.domain_name}" },
        { name = "SQS_S3_CLEANUP_QUEUE_URL", value = aws_sqs_queue.s3_cleanup.url },
        { name = "SQS_STORAGE_CALCULATION_QUEUE_URL", value = aws_sqs_queue.storage_calculation.url },
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
          "awslogs-stream-prefix" = "s3-queue-worker"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "s3_cleanup_queue_worker" {
  name            = "${var.app_name}-${var.environment}-s3-queue-worker"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.s3_cleanup_queue_worker.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = true
  }
}
