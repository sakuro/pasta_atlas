# ACM certificate for CloudFront (must be in us-east-1)
resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.us_east_1
  domain_name       = var.app_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.cloudfront.arn

  validation_record_fqdns = [
    for record in gandi_livedns_record.cloudfront_validation : "${record.name}.layer8.works"
  ]
}

moved {
  from = gandi_livedns_record.alb_validation
  to   = gandi_livedns_record.cloudfront_validation
}

resource "gandi_livedns_record" "cloudfront_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone   = "layer8.works"
  name   = trimsuffix(each.value.name, ".layer8.works.")
  type   = each.value.type
  ttl    = 300
  values = [each.value.value]
}

resource "aws_acm_certificate" "mapshots" {
  provider                  = aws.us_east_1
  domain_name               = var.maps_domain_name
  subject_alternative_names = var.maps_additional_domain_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "gandi_livedns_record" "mapshots_validation" {
  for_each = {
    for dvo in aws_acm_certificate.mapshots.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    } if endswith(dvo.domain_name, ".layer8.works")
  }

  zone   = "layer8.works"
  name   = trimsuffix(each.value.name, ".layer8.works.")
  type   = each.value.type
  ttl    = 300
  values = [each.value.value]
}

resource "cloudflare_dns_record" "mapshots_validation" {
  for_each = {
    for dvo in aws_acm_certificate.mapshots.domain_validation_options : dvo.domain_name => {
      name  = trimsuffix(dvo.resource_record_name, ".")
      type  = dvo.resource_record_type
      value = trimsuffix(dvo.resource_record_value, ".")
    } if endswith(dvo.domain_name, ".${var.cloudflare_zone_name}")
  }

  zone_id = data.cloudflare_zone.main.id
  name    = each.value.name
  type    = each.value.type
  content = each.value.value
  ttl     = 300
  proxied = false
}

resource "aws_acm_certificate_validation" "mapshots" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.mapshots.arn

  validation_record_fqdns = concat(
    [for record in gandi_livedns_record.mapshots_validation : "${record.name}.layer8.works"],
    [for record in cloudflare_dns_record.mapshots_validation : record.name],
  )
}
