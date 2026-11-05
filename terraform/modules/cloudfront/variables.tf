###########################################
## CLOUDFRONT VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "website_bucket_regional_domain_name" {
  description = "Website bucket regional domain name"
  type        = string
}

variable "cloudfront_ops_bucket_regional_domain_name" {
  description = "CloudFront bucket regional domain name"
  type        = string
}

variable "website_bucket" {
  description = "Website S3 bucket"
  type        = string
}

variable "cloudfront_ops_bucket" {
  description = "CloudFront S3 bucket"
  type        = string
}

variable "domain_name" {
  description = "Root domain name already hosted in Route 53 (e.g. cloudwithdarvin.com). Public traffic goes through CloudFront at this domain."
  type        = string
}

variable "cloudfront_ops_bucket_domain_name" {
  description = "CloudFront error page S3 bucket domain name"
  type        = string
}

variable "geo_restriction_locations" {
  description = "List of country codes for geo restriction (US, CA, etc. Empty list = no restriction)"
  type        = list(string)
  default     = ["US", "CA", "AU", "NZ", "SG"]
}

variable "frontend_acm_certificate_arn" {
  description = "ACM certificate"
  type        = string
}

variable "s3_bucket_website_arn" {
  description = "Website S3 bucket ARN"
  type        = string
}

variable "s3_bucket_cloudfront_ops_arn" {
  description = "Website S3 bucket ARN"
  type        = string
}

variable "s3_bucket_website_id" {
  description = "Website S3 bucket ID"
  type        = string
}

variable "s3_bucket_cloudfront_ops_id" {
  description = "Website S3 bucket ID"
  type        = string
}

variable "data_cf_caching_optimized_id" {
  description = "CF caching optimized ID"
  type        = string
}

variable "data_cf_cors_s3_origin_id" {
  description = "CF cors s3 origin ID"
  type        = string
}

variable "data_cf_security_headers_id" {
  description = "CF security headers ID"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "WAF web acl ARN"
  type        = string
}

variable "backend_api_subdomain" {
  description = "Public-facing API subdomain, also served through CloudFront (e.g. api -> api.cloudwithdarvin.com)"
  type        = string
}

variable "backend_cloudfront_price_class" {
  description = "CloudFront price class controlling which edge locations serve traffic. PriceClass_100 = US/Canada/Europe only (cheapest), PriceClass_200 adds Asia/Africa/Oceania, PriceClass_All = every edge location."
  type        = string

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.backend_cloudfront_price_class)
    error_message = "cloudfront_price_class must be one of: PriceClass_100, PriceClass_200, PriceClass_All."
  }
}

variable "backend_origin_record_name" {
  description = "FQDN of the Route 53 alias record pointing at the ALB (CloudFront's origin hostname)"
  type        = string
}

variable "backend_cloudfront_origin_secret_result" {
  description = "Shared secret value CloudFront sends to the origin (e.g. as a custom header) so the ALB can verify requests came through CloudFront"
  type        = string
}

variable "backend_acm_cloudfront_certificate_arn" {
  description = "ARN of the validated us-east-1 ACM certificate used by CloudFront's viewer TLS"
  type        = string
}

variable "backend_acm_origin_certificate_arn" {
  description = "ARN of the validated regional ACM certificate used by the ALB HTTPS listener"
  type        = string
}
