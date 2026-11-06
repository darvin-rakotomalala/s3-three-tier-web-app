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

variable "origin_subdomain" {
  description = "Internal, non-advertised subdomain that resolves directly to the ALB (e.g. origin -> origin.cloudwithdarvin.com). Used exclusively as CloudFront's origin domain name and as the Subject Alternative Name on the ALB's own regional ACM certificate, so CloudFront can validate TLS hostname matching when connecting to the origin over HTTPS."
  type        = string
}

variable "route53_zone_id" {
  description = "Zone ID of the existing Route 53 public hosted zone for var.domain_name"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "CloudFront's own *.cloudfront.net domain name (the public DNS records alias to this)"
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "Route 53 hosted zone ID of the CloudFront distribution (use as the alias target zone_id)"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB's own DNS name — internal use only, not reachable from outside CloudFront's IP ranges"
  type        = string
}

variable "alb_zone_id" {
  description = "The Route 53 hosted zone ID of the Application Load Balancer, used when creating alias records that point to the ALB."
  type        = string
}
