# ACM certificate for CloudFront (must be in us-east-1)
resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.us_east_1
  domain_name       = var.app_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records are identical to the ALB cert for the same domain.
resource "aws_acm_certificate_validation" "cloudfront" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.cloudfront.arn

  validation_record_fqdns = [
    for record in gandi_livedns_record.alb_validation : "${record.name}.layer8.works"
  ]
}

# ACM certificate for ALB (ap-northeast-1)
resource "aws_acm_certificate" "alb" {
  domain_name       = var.app_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "gandi_livedns_record" "alb_validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "alb" {
  certificate_arn = aws_acm_certificate.alb.arn

  validation_record_fqdns = [
    for record in gandi_livedns_record.alb_validation : "${record.name}.layer8.works"
  ]
}
