resource "aws_acm_certificate" "mapshots" {
  provider          = aws.us_east_1
  domain_name       = var.maps_domain_name
  validation_method = "DNS"

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
    }
  }

  zone   = "layer8.works"
  name   = trimsuffix(each.value.name, ".layer8.works.")
  type   = each.value.type
  ttl    = 300
  values = [each.value.value]
}

resource "aws_acm_certificate_validation" "mapshots" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.mapshots.arn

  validation_record_fqdns = [
    for record in gandi_livedns_record.mapshots_validation : "${record.name}.layer8.works"
  ]
}
