############################################
# VPC Interface Endpoints
#
# SSM / SSM Messages / EC2 Messages let Systems Manager manage the app-tier
# EC2 instances with no internet access — no bastion host, no SSH inbound,
# no public IP. The Secrets Manager endpoint lets the app tier read the DB
# credentials secret without routing that traffic through NAT/the internet.
############################################

locals {
  ssm_interface_services = toset([
    "ssm",
    "ssmmessages",
    "ec2messages",
  ])
}

resource "aws_vpc_endpoint" "ssm_interfaces" {
  for_each = local.ssm_interface_services

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.primary_region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.app_subnet_ids
  security_group_ids  = [var.ssm_endpoints_security_group_id]
  private_dns_enabled = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSSMAccess"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "ssm:*",
          "ssmmessages:*",
          "ec2messages:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = var.current_account_id
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-vpce-${each.key}"
  })
}

# ---------- Secrets Manager Interface Endpoint ----------
# Restricted to reading only the RDS master-credentials secret.
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.primary_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.app_subnet_ids
  security_group_ids  = [var.ssm_endpoints_security_group_id]
  private_dns_enabled = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowReadDbCredentialsSecretOnly"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.db_master_user_secret_arn
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = var.current_account_id
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-vpce-secretsmanager"
  })
}
