############################################
# CLOUDWATCH OUTPUTS
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "current_partition" {
  description = "Current partition account ID"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period (days) before export to S3 for long-term storage"
  type        = number
}

variable "cpu_threshold_percent" {
  description = "RDS CPUUtilization alarm threshold (%)"
  type        = number
}

variable "connection_threshold_percent" {
  description = "RDS DatabaseConnections alarm threshold, as a percentage of the computed max_connections"
  type        = number
}

variable "monthly_budget_ec2_usd" {
  description = "Monthly budget limit (USD) for EC2 application-tier spend"
  type        = number
}

variable "monthly_budget_rds_usd" {
  description = "Monthly budget limit (USD) for RDS spend"
  type        = number
}

variable "monthly_budget_cloudfront_usd" {
  description = "Monthly budget limit (USD) for CloudFront spend"
  type        = number
}

variable "kms_cloudwatch_key_arn" {
  description = "ARN of the KMS key used for CloudWatch Logs / SNS encryption"
  type        = string
}

variable "sns_alerts_topic_arn" {
  description = "The Amazon Resource Name (ARN) of the SNS topic used for alerts"
  type        = string
}

variable "alb_arn_suffix" {
  description = "The ARN suffix for use with CloudWatch Metrics."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "The ARN suffix for use with CloudWatch Metrics."
  type        = string
}

variable "cloudfront_distribution_id" {
  type        = string
  description = "The ID of the CloudFront distribution (e.g., E1A2B3C4D5E6F7)."
}

variable "app_autoscaling_group_name" {
  description = "Name of the Auto Scaling Group managing the web fleet"
  type        = string
}

variable "db_instance_main_identifier" {
  description = "The main identifier of DB instance."
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class for the primary PostgreSQL instance"
  type        = string
}
