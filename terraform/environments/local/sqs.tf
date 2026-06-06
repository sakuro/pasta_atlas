resource "aws_sqs_queue" "s3_cleanup" {
  name = "pasta-atlas-local-s3-cleanup"
}

resource "aws_sqs_queue" "storage_calculation" {
  name = "pasta-atlas-local-storage-calculation"
}
