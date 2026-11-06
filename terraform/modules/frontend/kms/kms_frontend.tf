###########################################
## KMS KEY FOR FRONTEND
###########################################

resource "aws_kms_key" "s3_key" {
  description             = "KMS key for frontend encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-encryption-key"
  })
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/${var.naming_prefix}-encrypt-s3"
  target_key_id = aws_kms_key.s3_key.key_id
}

data "aws_iam_policy_document" "s3_key_policy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    actions = [
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
      "kms:UntagResource"
    ]
    resources = [aws_kms_key.s3_key.arn]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.current_account_id}:root"]
    }
  }

  statement {
    sid    = "Allow S3 to use the key"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.s3_key.arn]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }

  statement {
    sid    = "Allow CloudFront to use the key"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.s3_key.arn]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
  }
}

resource "aws_kms_key_policy" "s3_key" {
  key_id = aws_kms_key.s3_key.id
  policy = data.aws_iam_policy_document.s3_key_policy.json
}
