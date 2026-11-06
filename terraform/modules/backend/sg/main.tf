############################################
# Security Groups
# Each SG uses standalone aws_vpc_security_group_ingress_rule /
# aws_vpc_security_group_egress_rule resources (never inline rules) to avoid
# circular dependencies between the ALB / App / RDS / endpoint groups.
############################################

# AWS-managed, auto-updating prefix list covering only the IP ranges
# CloudFront actually uses to connect to custom origins. Restricting the ALB
# to this list means the ALB can no longer be reached directly from the
# public internet — only through CloudFront.
data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# ---------- ALB-SG: reachable only from CloudFront ----------
resource "aws_security_group" "alb" {
  name        = "${var.naming_prefix}-ALB-SG"
  description = "Security group for the Application Load Balancer - ingress restricted to CloudFront origin-facing IP ranges"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_from_cloudfront" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from CloudFront only"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Restrict ALB outbound traffic solely to the application tier"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

# ---------- EC2-APP-SG: Application Tier ----------
resource "aws_security_group" "app" {
  name        = "${var.naming_prefix}-EC2-APP-SG"
  description = "Security group for Spring Boot application instances"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-ec2-app-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow application traffic from ALB only"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_to_rds" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow application tier to reach RDS PostgreSQL instance"
  referenced_security_group_id = aws_security_group.rds.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_to_ssm_endpoints" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow HTTPS egress to SSM / Secrets Manager interface endpoints"
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_https_egress" {
  security_group_id = aws_security_group.app.id
  description       = "Allow HTTPS egress for OS updates, CloudWatch APIs and S3 (via gateway endpoint)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_http_egress" {
  security_group_id = aws_security_group.app.id
  description       = "Allow HTTP egress for Linux package repository mirrors"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# ---------- RDS-SG: Database Tier ----------
resource "aws_security_group" "rds" {
  name        = "${var.naming_prefix}-RDS-SG"
  description = "Security group for isolated RDS PostgreSQL instance"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-rds-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  security_group_id            = aws_security_group.rds.id
  description                  = "Allow database traffic from application tier only"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
}

# Note: RDS requires zero egress rules — stateful connection tracking handles
# return responses to the app tier automatically.

# ---------- VPCE-SG: Interface VPC Endpoints (SSM + Secrets Manager) ----------
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.naming_prefix}-SSM-SG"
  description = "Security group for SSM and Secrets Manager Interface VPC Endpoints"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-ssm-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_from_app" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  description                  = "Allow HTTPS from application tier EC2 instances"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}
