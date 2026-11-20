output "s3_bucket_name" {
  value = aws_s3_bucket.mapshots.bucket
}

# The `cloudfront_*` outputs belong to the mapshots distribution (map tiles); the
# `app_cloudfront_*` outputs belong to the application distribution. Domain names are
# bare host names without a scheme.
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.mapshots.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.mapshots.id
}

output "app_cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.app.id
}

output "app_cloudfront_domain_name" {
  value = aws_cloudfront_distribution.app.domain_name
}

output "lambda_artifacts_bucket" {
  value = aws_s3_bucket.lambda_artifacts.bucket
}

output "assets_bucket" {
  value = aws_s3_bucket.assets.bucket
}

output "rds_endpoint" {
  value     = aws_db_instance.main.endpoint
  sensitive = true
}

output "session_secret_ssm_path" {
  value = aws_ssm_parameter.session_secret.name
}

output "sqs_s3_cleanup_queue_url" {
  value = aws_sqs_queue.s3_cleanup.url
}
