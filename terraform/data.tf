######################################
# DATA SOURCES
######################################

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

# Data source to get the correct ELB service account ID for the region
data "aws_elb_service_account" "main" {}

# Look up the existing hosted zone (no new zone is created)
data "aws_route53_zone" "existing" {
  name         = var.domain_name
  private_zone = false
}

# Availability zones available in the target region
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "cors_s3_origin" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "Managed-SecurityHeadersPolicy"
}
