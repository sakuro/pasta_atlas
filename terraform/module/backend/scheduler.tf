resource "aws_iam_role" "scheduler" {
  name               = "${var.app_name}-${var.environment}-scheduler"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role.json
}

data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "scheduler" {
  name   = "${var.app_name}-${var.environment}-scheduler"
  policy = data.aws_iam_policy_document.scheduler.json
}

data "aws_iam_policy_document" "scheduler" {
  statement {
    actions   = ["ecs:RunTask"]
    resources = [aws_ecs_task_definition.app.arn]
  }

  statement {
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.app.arn,
      aws_iam_role.execution.arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "scheduler" {
  role       = aws_iam_role.scheduler.name
  policy_arn = aws_iam_policy.scheduler.arn
}

resource "aws_scheduler_schedule" "cleanup_guest_maps" {
  name = "${var.app_name}-${var.environment}-cleanup-guest-maps"

  flexible_time_window {
    mode = "OFF"
  }

  # UTC 02:00 daily — after S3 lifecycle processing (UTC midnight)
  schedule_expression          = "cron(0 2 * * ? *)"
  schedule_expression_timezone = "UTC"

  target {
    arn      = aws_ecs_cluster.main.arn
    role_arn = aws_iam_role.scheduler.arn

    ecs_parameters {
      task_definition_arn = aws_ecs_task_definition.app.arn
      launch_type         = "FARGATE"

      network_configuration {
        subnets          = data.aws_subnets.default.ids
        security_groups  = [aws_security_group.app.id]
        assign_public_ip = true
      }
    }

    input = jsonencode({
      containerOverrides = [{
        name    = var.app_name
        command = ["bundle", "exec", "rake", "cleanup:guest_maps"]
      }]
    })
  }
}
