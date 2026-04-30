variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "maps_domain_name" {
  type        = string
  description = "Domain name for the CloudFront mapshots distribution"
}

variable "allowed_origins" {
  type        = list(string)
  description = "CORS allowed origins for presigned URL uploads"
}

variable "cloudfront_price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "presigned_url_expiry" {
  type    = number
  default = 3600
}
