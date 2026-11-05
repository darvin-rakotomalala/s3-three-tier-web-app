############################################
# AWS SYSTEMS MANAGER PARAMETER VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "ec2_linux_kms_key_id" {
  description = "ID of the custom KMS key"
  type        = string
}

variable "ec2_linux_log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
}
