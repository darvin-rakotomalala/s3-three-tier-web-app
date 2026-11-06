#########################################################
# MAIN VARIABLES
#########################################################

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "team_name" {
  description = "Team name"
  type        = string
}

variable "cost_center" {
  description = "Cost center"
  type        = string
}

variable "compliance" {
  description = "Compliance"
  type        = string
}

variable "bucket_name" {
  description = "Bucket name"
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

variable "domain_name" {
  description = "The domain name for the website"
  type        = string
}

variable "email_subscriptions" {
  description = "A list of email addresses to subscribe to the SNS topic"
  type        = list(string)
}

variable "source_files" {
  description = "HTML files"
  type        = string
}

###---- BACKEND PROVISIONING

############################################
# MAIN VARIABLES
############################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

# 3-AZ Multi-AZ architecture (Technical Spec requirement)
variable "availability_zones" {
  description = "Availability Zones to deploy across — 3 AZs for Multi-AZ high availability"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 Availability Zones are required."
  }
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT Gateway instead of one per AZ. Set false (default) for full HA, one NAT Gateway per AZ, per the Technical Spec."
  type        = bool
}

variable "alert_emails" {
  description = "Email addresses subscribed to the shared SNS alerts topic"
  type        = list(string)
}

variable "app_port" {
  description = "TCP port the Spring Boot application listens on"
  type        = number
}

variable "db_port" {
  description = "TCP port PostgreSQL listens on"
  type        = number
}

variable "jar_bucket_name" {
  description = "Name of the S3 bucket that stores the Spring Boot application JAR file"
  type        = string
}

variable "api_subdomain" {
  description = "Public-facing API subdomain, also served through CloudFront (e.g. api -> api.cloudwithdarvin.com)"
  type        = string
}

variable "origin_subdomain" {
  description = "Internal, non-advertised subdomain that resolves directly to the ALB (e.g. origin -> origin.cloudwithdarvin.com). Used exclusively as CloudFront's origin domain name and as the Subject Alternative Name on the ALB's own regional ACM certificate, so CloudFront can validate TLS hostname matching when connecting to the origin over HTTPS."
  type        = string
}

variable "db_engine_version" {
  description = "Preferred PostgreSQL major version (latest stable minor is resolved automatically)"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class for the primary PostgreSQL instance"
  type        = string
}

variable "db_allocated_storage" {
  description = "Initial allocated storage (GiB) for the RDS instance"
  type        = number
}

variable "db_max_allocated_storage" {
  description = "Storage autoscaling ceiling (GiB) for the RDS instance"
  type        = number
}

variable "db_name" {
  description = "Initial database name created on the RDS instance"
  type        = string
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
}

variable "db_multi_az" {
  description = "Enable Multi-AZ synchronous standby for the RDS instance"
  type        = bool
}

variable "db_backup_retention_days" {
  description = "Automated backup retention period (days)"
  type        = number
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

variable "cloudfront_price_class" {
  description = "CloudFront price class controlling which edge locations serve traffic. PriceClass_100 = US/Canada/Europe only (cheapest), PriceClass_200 adds Asia/Africa/Oceania, PriceClass_All = every edge location."
  type        = string

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "cloudfront_price_class must be one of: PriceClass_100, PriceClass_200, PriceClass_All."
  }
}

variable "health_check_path" {
  description = "HTTP path used by the ALB target group and Spring Boot Actuator health checks"
  type        = string
}

variable "enable_deletion_protection" {
  description = "Enable ALB deletion protection. Recommended true for prod; defaults false so dev/sandbox environments can be torn down freely."
  type        = bool
}

variable "asg_min_size" {
  description = "Minimum number of instances in the application-tier Auto Scaling Group"
  type        = number
}

variable "asg_max_size" {
  description = "Maximum number of instances in the application-tier Auto Scaling Group"
  type        = number
}

variable "asg_desired_capacity" {
  description = "Desired starting capacity of the application-tier Auto Scaling Group"
  type        = number
}

variable "on_demand_base_capacity" {
  description = "Minimum number of instances in the ASG that are always On-Demand before any Spot instances are used"
  type        = number

  validation {
    condition     = var.on_demand_base_capacity >= 0
    error_message = "on_demand_base_capacity must be 0 or greater."
  }
}

variable "on_demand_percentage_above_base" {
  description = "Percentage of instances above the base capacity that are On-Demand; the remainder are Spot (0-100)"
  type        = number

  validation {
    condition     = var.on_demand_percentage_above_base >= 0 && var.on_demand_percentage_above_base <= 100
    error_message = "on_demand_percentage_above_base must be between 0 and 100."
  }
}

# Default instance type baked into the launch template (single string)
variable "instance_type" {
  description = "Default EC2 instance type for the launch template"
  type        = string
}

# Instance types the ASG may use (on-demand and spot), in priority order
variable "instance_type_overrides" {
  description = "Instance types for the ASG mixed instances policy overrides"
  type        = list(string)

  validation {
    condition     = length(var.instance_type_overrides) > 0
    error_message = "Provide at least one instance type."
  }
}

variable "jar_local_path" {
  description = "Path to the built JAR on the machine running terraform apply"
  type        = string
}

variable "jar_object_key" {
  description = "S3 key of the JAR. Must match JAR_NAME in the workflow and user_data.sh"
  type        = string
}
