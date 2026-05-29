resource "aws_sqs_queue" "s3_cleanup" {
  name = "${var.app_name}-${var.environment}-s3-cleanup"
}
