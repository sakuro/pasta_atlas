resource "aws_sqs_queue" "s3_cleanup" {
  name = "pasta-atlas-local-s3-cleanup"
}
