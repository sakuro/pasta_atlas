data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host_header" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_distribution" "app" {
  origin {
    # Connect to ALB over HTTP; HTTPS termination is handled by CloudFront.
    domain_name = aws_lb.app.dns_name
    origin_id   = "alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  price_class     = var.cloudfront_price_class
  aliases         = [var.app_domain_name]

  ordered_cache_behavior {
    path_pattern           = "/assets/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "alb"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  default_cache_behavior {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "alb"
    viewer_protocol_policy   = "redirect-to-https"
    compress                 = true
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cloudfront.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_cloudfront_response_headers_policy" "mapshots_cors" {
  name = "${var.app_name}-${var.environment}-mapshots-cors"

  cors_config {
    access_control_allow_credentials = false
    access_control_allow_headers { items = ["*"] }
    access_control_allow_methods { items = ["GET", "HEAD"] }
    access_control_allow_origins { items = var.allowed_origins }
    origin_override = true
  }
}

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
    allowed_methods             = ["GET", "HEAD"]
    cached_methods              = ["GET", "HEAD"]
    target_origin_id            = aws_s3_bucket.mapshots.id
    viewer_protocol_policy      = "redirect-to-https"
    compress                    = true
    cache_policy_id             = data.aws_cloudfront_cache_policy.caching_optimized.id
    response_headers_policy_id  = aws_cloudfront_response_headers_policy.mapshots_cors.id
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
