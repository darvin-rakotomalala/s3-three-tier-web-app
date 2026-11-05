############################################
# ALB VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "app_port" {
  description = "TCP port the Spring Boot application listens on"
  type        = number
}

variable "health_check_path" {
  description = "HTTP path used by the ALB target group and Spring Boot Actuator health checks"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Enable ALB deletion protection. Recommended true for prod; defaults false so dev/sandbox environments can be torn down freely."
  type        = bool
}

variable "alb_security_group_id" {
  description = "ID of the ALB-SG security group"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public (ALB) subnets"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "backend_acm_certificate_arn" {
  description = "ARN of the ACM certificate used by the ALB HTTPS listener (empty if domain_name was not set)"
  type        = string
}

variable "alb_logs_s3_bucket_id" {
  description = "The name/ID of the S3 bucket storing ALB access logs."
  type        = string
}

variable "alb_logs_s3_bucket_policy_id" {
  description = "The ID of the S3 bucket policy applied to the ALB access logs bucket."
  type        = string
}
