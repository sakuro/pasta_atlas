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
