###########################################
## CLOUDWATCH VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "cf_distribution_id" {
  description = "CloudFront distribution ID"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS alarm actions"
  type        = list(string)
}
