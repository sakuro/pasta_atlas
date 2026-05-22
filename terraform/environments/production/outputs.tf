output "s3_bucket_name" {
  value = aws_s3_bucket.mapshots.bucket
}

output "cloudfront_domain_name" {
  value = "https://${aws_cloudfront_distribution.mapshots.domain_name}"
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.mapshots.id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "rds_endpoint" {
  value     = aws_db_instance.main.endpoint
  sensitive = true
}

output "session_secret_ssm_path" {
  value = aws_ssm_parameter.session_secret.name
}

output "sqs_map_deletion_queue_url" {
  value = aws_sqs_queue.map_deletion.url
}
