############################################
# VPC VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

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
