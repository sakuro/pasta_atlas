resource "gandi_livedns_record" "app" {
  zone   = "layer8.works"
  name   = trimsuffix(var.app_domain_name, ".layer8.works")
  type   = "CNAME"
  ttl    = 300
  values = ["${aws_cloudfront_distribution.app.domain_name}."]
}

resource "gandi_livedns_record" "maps" {
  zone   = "layer8.works"
  name   = trimsuffix(var.maps_domain_name, ".layer8.works")
  type   = "CNAME"
  ttl    = 300
  values = ["${aws_cloudfront_distribution.mapshots.domain_name}."]
}
