###########################################
## IAM VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository"
  type        = string
}

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "current_partition" {
  description = "Current partition account ID"
  type        = string
  # default = data.aws_partition.current.partition
}

variable "db_master_user_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret holding the master credentials"
  type        = string
  sensitive   = true
}

variable "jar_artifacts_bucket_arn" {
  description = "ARN of the S3 bucket storing the Spring Boot JAR artifact"
  type        = string
}

variable "kms_key_jar_artifacts_arn" {
  description = "ARN of the KMS key used for JAR artifacts"
  type        = string
}

variable "kms_key_secrets_arn" {
  description = "ARN of Secrets Manager KMS key"
  type        = string
}

variable "kms_key_cloudwatch_arn" {
  description = "ARN of CloudWatch KMS key"
  type        = string
}

variable "log_group_app_tier_arn" {
  description = "ARN of CloudWatch log group App tier"
  type        = string
}

variable "region_current_name" {
  description = "Name of the current AWS region (e.g. us-east-1), typically passed in from data.aws_region.current.name in the calling module. Used to build region-specific ARNs such as the SSM document ARN."
  type        = string
}

variable "ssm_parameter_arn" {
  description = "ARN of the SSM parameter holding the CloudWatch Linux agent config"
  type        = string
}

variable "ec2_linux_kms_key_arn" {
  description = "ARN of the custom KMS key"
  type        = string
}
