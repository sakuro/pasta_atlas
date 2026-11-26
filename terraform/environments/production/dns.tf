locals {
  app_domain_names  = concat([var.app_domain_name], var.app_additional_domain_names)
  maps_domain_names = concat([var.maps_domain_name], var.maps_additional_domain_names)

  gandi_app_domain_names       = [for name in local.app_domain_names : name if endswith(name, ".layer8.works")]
  gandi_maps_domain_names      = [for name in local.maps_domain_names : name if endswith(name, ".layer8.works")]
  cloudflare_app_domain_names  = [for name in local.app_domain_names : name if name == var.cloudflare_zone_name || endswith(name, ".${var.cloudflare_zone_name}")]
  cloudflare_maps_domain_names = [for name in local.maps_domain_names : name if endswith(name, ".${var.cloudflare_zone_name}")]
}

moved {
  from = gandi_livedns_record.app[0]
  to   = gandi_livedns_record.app["pasta-atlas.layer8.works"]
}

moved {
  from = gandi_livedns_record.maps
  to   = gandi_livedns_record.maps["maps.pasta-atlas.layer8.works"]
}

resource "gandi_livedns_record" "app" {
  for_each = toset(local.gandi_app_domain_names)

  zone   = "layer8.works"
  name   = trimsuffix(each.value, ".layer8.works")
  type   = "CNAME"
  ttl    = 300
  values = ["${aws_cloudfront_distribution.app.domain_name}."]
}

resource "gandi_livedns_record" "maps" {
  for_each = toset(local.gandi_maps_domain_names)

  zone   = "layer8.works"
  name   = trimsuffix(each.value, ".layer8.works")
  type   = "CNAME"
  ttl    = 300
  values = ["${aws_cloudfront_distribution.mapshots.domain_name}."]
}

# A CNAME at the zone apex is allowed because Cloudflare flattens it.
resource "cloudflare_dns_record" "app" {
  for_each = toset(local.cloudflare_app_domain_names)

  zone_id = data.cloudflare_zone.main.id
  name    = each.value
  type    = "CNAME"
  content = aws_cloudfront_distribution.app.domain_name
  ttl     = 300
  # Proxying through Cloudflare would put a second CDN in front of CloudFront.
  proxied = false
}

resource "cloudflare_dns_record" "maps" {
  for_each = toset(local.cloudflare_maps_domain_names)

  zone_id = data.cloudflare_zone.main.id
  name    = each.value
  type    = "CNAME"
  content = aws_cloudfront_distribution.mapshots.domain_name
  ttl     = 300
  proxied = false
}
