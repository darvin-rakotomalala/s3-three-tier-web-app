###########################################
## CLOUDFRONT FRONTEND
###########################################

resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.naming_prefix}-frontend-oac"
  description                       = "OAC for frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_access_control" "error_pages" {
  name                              = "${var.naming_prefix}-error-pages-oac"
  description                       = "OAC for error pages S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Response headers policies
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "${var.naming_prefix}-security-headers"

  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000 # HSTS is configured above with 1-year max-age and include_subdomains enabled.
      include_subdomains         = true
      override                   = true
    }
  }
}

resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name              = var.website_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
    origin_id                = "S3-${var.website_bucket}"
  }

  # Error pages origin
  origin {
    domain_name              = var.cloudfront_ops_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.error_pages.id
    origin_id                = "S3-${var.cloudfront_ops_bucket}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name, "www.${var.domain_name}"]

  web_acl_id = var.waf_web_acl_arn

  # CloudFront access logging
  depends_on = [var.cloudfront_ops_bucket]
  logging_config {
    bucket          = var.cloudfront_ops_bucket_domain_name
    prefix          = "logs/"
    include_cookies = false
  }

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${var.website_bucket}"
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
    cache_policy_id            = var.data_cf_caching_optimized_id
    origin_request_policy_id   = var.data_cf_cors_s3_origin_id
    response_headers_policy_id = var.data_cf_security_headers_id
  }

  # Cache behavior for error pages
  ordered_cache_behavior {
    path_pattern             = "/error-pages/*"
    allowed_methods          = ["GET", "HEAD"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "S3-${var.cloudfront_ops_bucket}"
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = var.data_cf_caching_optimized_id
    origin_request_policy_id = var.data_cf_cors_s3_origin_id
  }

  restrictions {
    geo_restriction {
      restriction_type = length(var.geo_restriction_locations) > 0 ? "whitelist" : "none"
      locations        = var.geo_restriction_locations
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Custom error pages
  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/error-pages/404.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/error-pages/404.html"
  }

  custom_error_response {
    error_code         = 500
    response_code      = 500
    response_page_path = "/error-pages/500.html"
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-cf-distribution-frontend"
  })
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${var.s3_bucket_website_arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }
}

data "aws_iam_policy_document" "cloudfront_ops_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${var.s3_bucket_cloudfront_ops_arn}/error-pages/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }

  statement {
    sid    = "AllowCloudFrontLogging"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${var.s3_bucket_cloudfront_ops_arn}/logs/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = var.s3_bucket_website_id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}

resource "aws_s3_bucket_policy" "cloudfront_ops" {
  bucket = var.s3_bucket_cloudfront_ops_id
  policy = data.aws_iam_policy_document.cloudfront_ops_bucket_policy.json
}
