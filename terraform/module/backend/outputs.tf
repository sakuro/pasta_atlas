output "ecr_repository_url" {
  description = "ECR repository URL — push images here before deploying"
  value       = aws_ecr_repository.app.repository_url
}

output "rds_endpoint" {
  description = "RDS endpoint — use in DATABASE_URL: postgres://<user>:<pass>@<endpoint>/<db>"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "session_secret_ssm_path" {
  description = "SSM Parameter Store path for SESSION_SECRET"
  value       = aws_ssm_parameter.session_secret.name
}
