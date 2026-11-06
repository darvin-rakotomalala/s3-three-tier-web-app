############################################
# CF VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "domain_name" {
  description = "Root domain name already hosted in Route 53 (e.g. cloudwithdarvin.com). Public traffic goes through CloudFront at this domain."
  type        = string
}

variable "api_subdomain" {
  description = "Public-facing API subdomain, also served through CloudFront (e.g. api -> api.cloudwithdarvin.com)"
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront price class controlling which edge locations serve traffic. PriceClass_100 = US/Canada/Europe only (cheapest), PriceClass_200 adds Asia/Africa/Oceania, PriceClass_All = every edge location."
  type        = string

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "cloudfront_price_class must be one of: PriceClass_100, PriceClass_200, PriceClass_All."
  }
}

variable "origin_record_name" {
  description = "FQDN of the Route 53 alias record pointing at the ALB (CloudFront's origin hostname)"
  type        = string
}

variable "cloudfront_origin_secret_result" {
  description = "Shared secret value CloudFront sends to the origin (e.g. as a custom header) so the ALB can verify requests came through CloudFront"
  type        = string
}

variable "acm_cloudfront_certificate_arn" {
  description = "ARN of the validated us-east-1 ACM certificate used by CloudFront's viewer TLS"
  type        = string
}

variable "acm_origin_certificate_arn" {
  description = "ARN of the validated regional ACM certificate used by the ALB HTTPS listener"
  type        = string
}
