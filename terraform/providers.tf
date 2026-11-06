# AWS provider
terraform {
  required_version = ">= 1.14.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Allows 6.x.x, blocks 7.0.0
    }
  }
}

# Primary
provider "aws" {
  region = var.primary_region
}

# CloudFront's ACM *viewer* certificate must always be requested in
# us-east-1, regardless of which region the rest of the stack lives in.
# This alias guarantees that even if var.primary_region is ever changed.
# It is passed into module.acm via the `providers` argument on the module call.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
