output "s3_bucket_name" {
  value = aws_s3_bucket.mapshots.bucket
}

output "rds_endpoint" {
  value     = aws_db_instance.main.endpoint
  sensitive = true
}
