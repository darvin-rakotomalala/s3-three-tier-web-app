###########################################
## DNSSEC for DNS security
###########################################

resource "aws_kms_key" "dnssec" {
  # Must be in us-east-1
  customer_master_key_spec = "ECC_NIST_P256"
  key_usage                = "SIGN_VERIFY"
  deletion_window_in_days  = 7

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-dnssec-key"
  })
}

resource "aws_kms_alias" "dnssec" {
  name          = "alias/${var.naming_prefix}-${replace(var.domain_name, ".", "-")}-dnssec"
  target_key_id = aws_kms_key.dnssec.key_id
}

resource "aws_kms_key_policy" "dnssec" {
  key_id = aws_kms_key.dnssec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.current_account_id}:root"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:Create*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:Sign"
        ]
        Resource = [aws_kms_key.dnssec.arn]
      },
      {
        Sid    = "Allow Route 53 DNSSEC Service"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign"
        ]
        Resource = [aws_kms_key.dnssec.arn]
      },
      {
        Sid    = "Allow Route 53 DNSSEC to CreateGrant"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Resource = [aws_kms_key.dnssec.arn]
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = true
          }
        }
      }
    ]
  })
  depends_on = [aws_kms_key.dnssec]
}

# Create the Key Signing Key (KSK) attached to the existing zone
resource "aws_route53_key_signing_key" "main" {
  hosted_zone_id             = var.data_aws_route53_zone_existing_zone_id
  key_management_service_arn = aws_kms_key.dnssec.arn
  name                       = "${var.naming_prefix}-${replace(var.domain_name, ".", "-")}-ksk"
  status                     = "ACTIVE"
  depends_on                 = [aws_kms_key.dnssec, aws_kms_key_policy.dnssec]
}

# Enable DNSSEC on the existing hosted zone
resource "aws_route53_hosted_zone_dnssec" "main" {
  hosted_zone_id = var.data_aws_route53_zone_existing_zone_id
  depends_on     = [aws_route53_key_signing_key.main]
}

# Route53 records for the domain
resource "aws_route53_record" "root" {
  zone_id = var.data_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cf_website_domain_name
    zone_id                = var.cf_website_hosted_zone_id
    evaluate_target_health = false
  }
}

# distribution alias domain
resource "aws_route53_record" "www" {
  zone_id = var.data_zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.cf_website_domain_name
    zone_id                = var.cf_website_hosted_zone_id
    evaluate_target_health = false
  }
}
