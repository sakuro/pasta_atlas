resource "gandi_livedns_record" "app" {
  count = var.app_dns_enabled ? 1 : 0

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

resource "cloudflare_dns_record" "maps" {
  for_each = toset(var.maps_additional_domain_names)

  zone_id = data.cloudflare_zone.main.id
  name    = each.value
  type    = "CNAME"
  content = aws_cloudfront_distribution.mapshots.domain_name
  ttl     = 300
  # Proxying through Cloudflare would put a second CDN in front of CloudFront.
  proxied = false
}
