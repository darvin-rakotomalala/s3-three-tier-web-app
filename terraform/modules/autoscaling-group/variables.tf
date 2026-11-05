############################################
# ASG VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "app_launch_template_id" {
  description = "ID of the launch template used by the web fleet"
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

variable "app_subnet_ids" {
  description = "IDs of the private application-tier subnets"
  type        = list(string)
}

variable "alb_target_group_arn" {
  description = "ARN of the application load balancer target group"
  type        = string
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

variable "alb_target_group_resource_label" {
  description = "Resource label (ALB and target group ARN suffixes) for the ALBRequestCountPerTarget target-tracking scaling metric"
  type        = string
}

variable "launch_template_latest_version" {
  description = "Latest version number of the web fleet launch template"
  type        = string
}
