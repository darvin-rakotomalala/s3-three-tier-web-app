############################################
# S3 BUCKET FOR APPLICATION LOAD BALANCER ACCESS LOGS
############################################

# ---------- S3 Bucket for ALB Access Logs ----------
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${var.naming_prefix}-alb-access-logs-${var.current_account_id}"
  force_destroy = true # Set to true only if you want Terraform to delete non-empty buckets on destroy

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb-access-logs"
  })
}

resource "aws_s3_bucket_ownership_controls" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket                  = aws_s3_bucket.alb_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bucket Policy allowing ALB to write access logs
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          AWS = var.elb_service_account_main_arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      }
    ]
  })
}

# ---------- S3 Bucket Lifecycle Configuration for ALB Logs ----------
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "alb-logs-lifecycle"
    status = "Enabled"

    # Optional: If you enable object versioning on the bucket,
    # you can clean up noncurrent versions.
    # noncurrent_version_expiration {
    #   noncurrent_days = 90
    # }

    # Transition current logs to Standard-IA (Infrequent Access) after 30 days to save costs
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition current logs to Glacier Flexible Retrieval or Glacier Deep Archive after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Expire (permanently delete) logs after 365 days (adjust based on your compliance/auditing requirements)
    expiration {
      days = 365
    }
  }
}
