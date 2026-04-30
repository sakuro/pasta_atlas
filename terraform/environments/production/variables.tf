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

variable "cloudfront_price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "presigned_url_expiry" {
  type    = number
  default = 3600
}
