output "s3_bucket_name" {
  value = aws_s3_bucket.mapshots.bucket
}

output "sqs_map_deletion_queue_url" {
  value = aws_sqs_queue.map_deletion.url
}
