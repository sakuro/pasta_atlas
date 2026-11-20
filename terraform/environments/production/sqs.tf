locals {
  # Visibility timeout is six times the worker function timeout, as AWS recommends.
  worker_timeout_seconds = 60
}

resource "aws_sqs_queue" "s3_cleanup_dlq" {
  name                      = "${var.app_name}-${var.environment}-s3-cleanup-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "s3_cleanup" {
  name                       = "${var.app_name}-${var.environment}-s3-cleanup"
  visibility_timeout_seconds = local.worker_timeout_seconds * 6

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.s3_cleanup_dlq.arn
    maxReceiveCount     = 5
  })
}
