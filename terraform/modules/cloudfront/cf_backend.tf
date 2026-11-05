############################################
# CLOUDFRONT DISTRIBUTION FOR BACKEND
# Public traffic path is now: Route 53 -> CloudFront -> ALB -> ASG.
############################################

resource "aws_cloudfront_distribution" "backend" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.naming_prefix} — CloudFront in front of the ALB"
  price_class     = var.backend_cloudfront_price_class
  aliases         = ["${var.backend_api_subdomain}.${var.domain_name}"]
  http_version    = "http2and3"

  origin {
    domain_name = var.backend_origin_record_name # origin.<domain> -> ALB
    origin_id   = "alb-origin"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
    }

    # Only CloudFront knows this value; the ALB listener rule rejects any
    # request that doesn't present it (13-alb.tf).
    custom_header {
      name  = "X-Origin-Verify"
      value = var.backend_cloudfront_origin_secret_result
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # API traffic is dynamic — forward everything to the origin and don't
    # cache responses. (Swap in AWS-managed "CachingOptimized" /
    # "CachingDisabled" policy IDs here instead of forwarded_values if your
    # provider version prefers the cache-policy API over the legacy
    # forwarded_values block.)
    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization", "Accept", "Content-Type"]

      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.backend_acm_cloudfront_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # NOTE: CloudFront's classic `logging_config` (S3-only) was intentionally
  # left disabled here to stay consistent with removing the ALB's S3 access
  # log bucket elsewhere in this stack. CloudFront request-level metrics
  # (requests, error rate, bytes) are still available natively via
  # CloudWatch (see 19-cloudwatch-alb.tf) without needing a log bucket. If
  # you need raw per-request logs later, add:
  #   logging_config {
  #     bucket = <a dedicated logs bucket>.bucket_domain_name
  #     prefix = "cloudfront/"
  #   }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-cloudfront"
  })

  depends_on = [
    var.backend_acm_cloudfront_certificate_arn,
    var.backend_acm_origin_certificate_arn,
    var.backend_origin_record_name,
  ]
}
