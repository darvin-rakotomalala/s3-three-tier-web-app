############################################
# LAUNCH TEMPLATE VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "instance_profile_arn" {
  description = "Name of the EC2 instance profile attached to the application server"
  type        = string
}

# Default instance type baked into the launch template (single string)
variable "instance_type" {
  description = "Default EC2 instance type for the launch template"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "app_security_group_id" {
  description = "ID of the EC2-APP-SG security group"
  type        = string
}

variable "ebs_kms_key_arn" {
  description = "ARN of the KMS key used for EBS encryption"
  type        = string
}

variable "jar_artifacts_bucket_name" {
  description = "ID of the S3 bucket storing the Spring Boot JAR artifact"
  type        = string
}

variable "ssm_parameter_name" {
  description = "Name of the SSM parameter holding the CloudWatch Linux agent config"
  type        = string
}

variable "ec2_linux_kms_alias_arn" {
  description = "ARN of the KMS alias"
  type        = string
}

variable "ec2_linux_kms_key_policy_id" {
  description = "ID of the KMS key policy resource"
  type        = string
}
