###########################################
## ROUTE 53 VARIABLES
###########################################

variable "domain_name" {
  description = "The domain name for the website"
  type        = string
}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "data_zone_id" {
  description = "The domain name for the website"
  type        = string
}

variable "cf_website_domain_name" {
  description = "CloudFront domain name"
  type        = string
}

variable "cf_website_hosted_zone_id" {
  description = "CloudFront hosted zone id"
  type        = string
}

variable "data_aws_route53_zone_existing_zone_id" {
  description = "Existing hosted zone"
  type        = string
}
