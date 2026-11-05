############################################
# KMS FOR EC2 LINUX
############################################

resource "aws_kms_key" "custom_kms_key" {
  description             = "KMS key for ${var.naming_prefix}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-vpc"
  })
}

resource "aws_kms_alias" "key" {
  name          = "alias/${var.naming_prefix}"
  target_key_id = aws_kms_key.custom_kms_key.id
}

resource "aws_kms_key_policy" "encrypt_app" {
  key_id = aws_kms_key.custom_kms_key.id
  policy = jsonencode({
    Id = "${var.naming_prefix}-encryption"
    Statement = [
      {
        Action = [
          "kms:*"
        ]
        Effect = "Allow"
        Principal = {
          AWS = "${var.principal_root_arn}"
        }
        Resource = "*"
        Sid      = "Enable IAM User Permissions"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "ssm.amazonaws.com"
        },
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.${var.primary_region}.amazonaws.com"
          }
        }
      },
      {
        Effect : "Allow",
        Principal : {
          Service : "${var.principal_logs_arn}"
        },
        Action : [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ],
        Resource : "*",
        Condition : {
          ArnEquals : {
            "kms:EncryptionContext:aws:logs:arn" : [var.log_group_arn]
          }
        }
      }
    ]
    Version = "2012-10-17"
  })
}
