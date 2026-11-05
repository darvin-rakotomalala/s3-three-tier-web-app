###########################################
## KMS VARIABLES
###########################################

variable "primary_region" {
  description = "Primary region"
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

variable "principal_root_arn" {
  type        = string
  description = "ARN of the root principal (e.g., the AWS account root) that is granted administrative access to the resource, typically in a KMS key policy."
}

variable "principal_logs_arn" {
  type        = string
  description = "ARN of the CloudWatch Logs service principal (e.g., logs.<region>.amazonaws.com) that is allowed to use the resource."
}

variable "log_group_arn" {
  type        = string
  description = "ARN of the CloudWatch log group that the permissions are scoped to, typically used in an encryption context condition."
}
