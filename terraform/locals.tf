locals {
  common_tags = {
    ManagedBy   = "Terraform"
    Region      = var.primary_region # primary or secondary
    Environment = var.environment    # dev, staging, prod
    Project     = var.project_name   # ce
    Owner       = var.team_name      # demo
    CostCenter  = var.cost_center    # "engineering"
    Compliance  = var.compliance     # "internal"
    # The timestamp() function returns a UTC timestamp string in RFC 3339 format.
    deployment_timestamp = timestamp()
  }

  naming_prefix = "${var.project_name}-${var.environment}"

  principal_root_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  principal_logs_arn = "logs.${var.primary_region}.amazonaws.com"
  log_group_arn      = "arn:aws:logs:${var.primary_region}:${data.aws_caller_identity.current.account_id}:log-group:/${local.naming_prefix}/ec2/linux"
}
