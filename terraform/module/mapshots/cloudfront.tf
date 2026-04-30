resource "aws_cloudfront_origin_access_control" "mapshots" {
  name                              = "${var.app_name}-${var.environment}-mapshots"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "mapshots" {
  origin {
    domain_name              = aws_s3_bucket.mapshots.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.mapshots.id
    origin_access_control_id = aws_cloudfront_origin_access_control.mapshots.id
  }

  enabled         = true
  is_ipv6_enabled = true
  price_class     = var.cloudfront_price_class
  aliases         = [var.maps_domain_name]

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.mapshots.id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.mapshots.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_s3_bucket_policy" "mapshots" {
  bucket = aws_s3_bucket.mapshots.id
  policy = data.aws_iam_policy_document.s3_cloudfront_read.json

  depends_on = [aws_s3_bucket_public_access_block.mapshots]
}

data "aws_iam_policy_document" "s3_cloudfront_read" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.mapshots.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.mapshots.arn]
    }
  }
}
