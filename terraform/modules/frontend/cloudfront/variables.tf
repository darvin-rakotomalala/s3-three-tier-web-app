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
  description = "The domain name for the website"
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

variable "acm_certificate_arn" {
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
