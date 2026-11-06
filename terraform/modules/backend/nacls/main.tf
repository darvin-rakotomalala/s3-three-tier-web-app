############################################
# Network ACLs (stateless, defense-in-depth layer on top of Security Groups)
#
# NOTE: NACLs only support plain CIDR blocks, not the CloudFront managed
# prefix list used to lock down the ALB Security Group (04-security-groups.tf).
# Public-subnet NACL rules stay open on 80/443 to 0.0.0.0/0; actual
# enforcement that only CloudFront can reach the ALB happens at the
# Security Group layer.
############################################

# ================= PUBLIC SUBNETS NACL =================
resource "aws_network_acl" "public" {
  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-public-nacl"
  })
}

resource "aws_network_acl_rule" "public_in_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_in_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public_in_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_out_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_out_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public_out_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# ================= APPLICATION-TIER SUBNETS NACL =================
resource "aws_network_acl" "app" {
  vpc_id     = var.vpc_id
  subnet_ids = var.app_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-app-nacl"
  })
}

resource "aws_network_acl_rule" "app_in_ephemeral" {
  network_acl_id = aws_network_acl.app.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "app_out_http" {
  network_acl_id = aws_network_acl.app.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "app_out_https" {
  network_acl_id = aws_network_acl.app.id
  rule_number    = 105
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "app_out_to_db" {
  network_acl_id = aws_network_acl.app.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = var.db_port
  to_port        = var.db_port
}

resource "aws_network_acl_rule" "app_out_ephemeral" {
  network_acl_id = aws_network_acl.app.id
  rule_number    = 120
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

# ================= DATABASE-TIER SUBNETS NACL =================
resource "aws_network_acl" "db" {
  vpc_id     = var.vpc_id
  subnet_ids = var.db_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-db-nacl"
  })
}

locals {
  az_count          = length(var.availability_zones)
  nat_gateway_count = var.single_nat_gateway ? 1 : local.az_count
}

# Inbound: PostgreSQL traffic, one rule per app-tier subnet CIDR (dynamic across all AZs)
resource "aws_network_acl_rule" "db_in_postgres_app" {
  count          = length(var.app_subnet_cidrs)
  network_acl_id = aws_network_acl.db.id
  rule_number    = 100 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.app_subnet_cidrs[count.index]
  from_port      = var.db_port
  to_port        = var.db_port
}

# Outbound: ephemeral return responses sent strictly back to each app-tier subnet
resource "aws_network_acl_rule" "db_out_ephemeral_app" {
  count          = length(var.app_subnet_cidrs)
  network_acl_id = aws_network_acl.db.id
  rule_number    = 100 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.app_subnet_cidrs[count.index]
  from_port      = 1024
  to_port        = 65535
}
