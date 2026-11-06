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

variable "app_autoscaling_group_name" {
  description = "The Auto Scaling Group managing the web fleet"
  type        = string
}

variable "jar_artifacts_bucket_name" {
  description = "ID of the S3 bucket storing the Spring Boot JAR artifact"
  type        = string
}
