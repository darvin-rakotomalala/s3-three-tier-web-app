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
