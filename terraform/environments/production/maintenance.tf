# The keys (maintenance, allow_ips, message, ends_at) change at run time through the
# ops:maintenance:* tasks, so Terraform manages only the store.
resource "aws_cloudfront_key_value_store" "maintenance" {
  name    = "${var.app_name}-${var.environment}-maintenance"
  comment = "Maintenance mode settings read by the ${var.app_name}-${var.environment}-maintenance function"
}

resource "aws_cloudfront_function" "maintenance" {
  name    = "${var.app_name}-${var.environment}-maintenance"
  runtime = "cloudfront-js-2.0"
  comment = "Answers 503 while maintenance mode is on"
  publish = true
  # The page is a separate file so that neither file has to escape the other; jsonencode
  # turns it into a JavaScript string literal.
  code = join("\n", [
    file("${path.module}/functions/maintenance.js"),
    "const PAGE = ${jsonencode(file("${path.module}/functions/maintenance.html"))};",
  ])

  key_value_store_associations = [aws_cloudfront_key_value_store.maintenance.arn]
}
