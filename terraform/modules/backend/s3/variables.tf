############################################
# S3 VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "jar_bucket_name" {
  description = "Name of the S3 bucket that stores the Spring Boot application JAR file"
  type        = string
}

variable "kms_key_jar_artifacts_arn" {
  description = "ARN of the KMS key used for JAR artifacts"
  type        = string
}

variable "ec2_app_role_arn" {
  description = "ARN of the EC2 application tier IAM role"
  type        = string
}

variable "jar_local_path" {
  description = "Path to the built JAR on the machine running terraform apply"
  type        = string
}

variable "jar_object_key" {
  description = "S3 key of the JAR. Must match JAR_NAME in the workflow and user_data.sh"
  type        = string
}
