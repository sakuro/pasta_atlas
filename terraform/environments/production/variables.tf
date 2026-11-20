variable "app_name" {
  type    = string
  default = "pasta-atlas"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "app_domain_name" {
  type    = string
  default = "pasta-atlas.layer8.works"
}

variable "maps_domain_name" {
  type    = string
  default = "maps.pasta-atlas.layer8.works"
}

variable "allowed_origins" {
  type    = list(string)
  default = ["https://pasta-atlas.layer8.works"]
}

variable "db_username" {
  type    = string
  default = "master"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "cloudfront_price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "presigned_url_expiry" {
  type    = number
  default = 3600
}

variable "github_client_id" {
  type    = string
  default = "Ov23liGNU3RVMN2XrLUC"
}

variable "discord_client_id" {
  type    = string
  default = "1506102791695761548"
}

variable "create_bastion" {
  type    = bool
  default = false
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["172.31.128.0/20", "172.31.144.0/20"]
}

variable "app_dns_enabled" {
  type    = bool
  default = true
}

variable "lambda_runtime" {
  type    = string
  default = "ruby4.0"
}

variable "web_adapter_layer_arn" {
  type    = string
  default = "arn:aws:lambda:ap-northeast-1:753240598075:layer:LambdaAdapterLayerArm64:30"
}

variable "app_memory_size" {
  type    = number
  default = 1024
}

variable "app_reserved_concurrency" {
  type    = number
  default = 10
}

variable "alarm_email" {
  description = "Address that receives CloudWatch alarm notifications. The subscription must be confirmed from the email."
  type        = string
  default     = null
}
