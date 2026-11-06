###########################################
# ACM certificate VARIABLES
###########################################

variable "domain_name" {
  description = "The domain name for the website"
  type        = string
}

variable "data_zone_id" {
  description = "The domain name for the website"
  type        = string
}

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}
