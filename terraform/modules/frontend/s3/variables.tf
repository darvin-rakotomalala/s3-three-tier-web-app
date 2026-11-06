###########################################
# S3 BUCKET VARIABLES
###########################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "s3_key_arn" {
  description = "KMS key for S3 bucket encryption"
  type        = string
}
