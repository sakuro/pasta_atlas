# Abandoned uploads leave a generation and S3 objects behind. The task removes the ones
# without activity for settings.stale_upload_days (see Operations::Uploads::CleanupStale).
resource "aws_scheduler_schedule" "stale_uploads_cleanup" {
  name                         = "${var.app_name}-${var.environment}-stale-uploads-cleanup"
  schedule_expression          = "cron(0 3 * * ? *)"
  schedule_expression_timezone = "Asia/Tokyo"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.task.arn
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ task = "cleanup:stale_uploads" })

    # The task is safe to repeat, and a failure raises the task function's error alarm.
    retry_policy {
      maximum_retry_attempts = 0
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name = "${var.app_name}-${var.environment}-scheduler"

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

resource "aws_iam_role_policy" "scheduler_invoke_task" {
  name   = "invoke-task"
  role   = aws_iam_role.scheduler.id
  policy = data.aws_iam_policy_document.scheduler_invoke_task.json
}

data "aws_iam_policy_document" "scheduler_invoke_task" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.task.arn]
  }
}
