variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "app_domain_name" {
  type        = string
  description = "Domain name for the web application (ALB)"
}

# Passed from mapshots module outputs
variable "s3_bucket_name" {
  type = string
}

variable "s3_bucket_arn" {
  type = string
}

variable "cloudfront_base_url" {
  type        = string
  description = "CloudFront base URL (https://...) for CLOUDFRONT_BASE_URL env var"
}

# RDS

variable "db_username" {
  type    = string
  default = "pasta_atlas"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

# ECS / Fargate

variable "container_port" {
  type    = number
  default = 3000
}

variable "container_cpu" {
  type    = number
  default = 256
}

variable "container_memory" {
  type    = number
  default = 512
}

variable "app_desired_count" {
  type    = number
  default = 1
}
