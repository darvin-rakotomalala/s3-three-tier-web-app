####################################################
# SNS VARIABLES
####################################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "email_subscriptions" {
  description = "A list of email addresses to subscribe to the SNS topic"
  type        = list(string)
}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "kms_cloudwatch_key_id" {
  description = "ID of the KMS key used for CloudWatch Logs / SNS encryption"
  type        = string
}
