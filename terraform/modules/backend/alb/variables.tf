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

variable "db_port" {
  description = "TCP port PostgreSQL listens on"
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

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate used by the ALB HTTPS listener (empty if domain_name was not set)"
  type        = string
}
