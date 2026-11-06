############################################
# KMS VARIABLES
############################################

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "current_partition" {
  description = "Current partition account ID"
  type        = string
}

variable "ec2_app_role_arn" {
  description = "ARN of the EC2 application tier IAM role"
  type        = string
}

variable "kms_cloudwatch_policy_json" {
  description = "The rendered JSON policy document for the CloudWatch and SNS KMS key."
  type        = string
}
