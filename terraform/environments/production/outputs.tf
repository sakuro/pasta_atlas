output "s3_bucket_name" {
  value = module.mapshots.s3_bucket_name
}

output "cloudfront_domain_name" {
  value = module.mapshots.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  value = module.mapshots.cloudfront_distribution_id
}

output "ecr_repository_url" {
  value = module.backend.ecr_repository_url
}

output "rds_endpoint" {
  value     = module.backend.rds_endpoint
  sensitive = true
}

output "session_secret_ssm_path" {
  value = module.backend.session_secret_ssm_path
}
