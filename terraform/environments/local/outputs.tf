output "s3_bucket_name" {
  value = aws_s3_bucket.mapshots.bucket
}

output "sqs_s3_cleanup_queue_url" {
  value = aws_sqs_queue.s3_cleanup.url
}
