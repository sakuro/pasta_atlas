output "s3_bucket_name" {
  description = "S3 bucket name — set as S3_BUCKET in app env"
  value       = aws_s3_bucket.mapshots.bucket
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.mapshots.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront domain — set as CLOUDFRONT_BASE_URL in app env"
  value       = "https://${aws_cloudfront_distribution.mapshots.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (needed for cache invalidation)"
  value       = aws_cloudfront_distribution.mapshots.id
}
