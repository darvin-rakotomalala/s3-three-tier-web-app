###########################################
# S3 BUCKET FOR CLOUDFRONT LOGS
###########################################

resource "aws_s3_bucket" "cloudfront_ops" {
  bucket        = "${var.naming_prefix}-cloudfront-ops-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-cloudfront-ops"
    Purpose = "bucket-cloudfront-ops"
  })
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_ops" {
  bucket = aws_s3_bucket.cloudfront_ops.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  # CloudFront logging requires ACL access. BucketOwnerPreferred provides security while enabling logging.
}

resource "aws_s3_bucket_acl" "cloudfront_ops" {
  depends_on = [
    aws_s3_bucket_ownership_controls.cloudfront_ops,
    aws_s3_bucket_public_access_block.cloudfront_ops
  ]
  bucket = aws_s3_bucket.cloudfront_ops.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "cloudfront_ops" {
  bucket = aws_s3_bucket.cloudfront_ops.id

  block_public_acls       = false
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = true

  # CloudFront logging requires ACL access. Security maintained through bucket policies.
}

resource "aws_s3_bucket_versioning" "cloudfront_ops" {
  bucket = aws_s3_bucket.cloudfront_ops.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_ops" {
  bucket = aws_s3_bucket.cloudfront_ops.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.s3_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_ops" {
  bucket = aws_s3_bucket.cloudfront_ops.id

  rule {
    id     = "abort_incomplete_uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "manage_log_files"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    # Move logs to cheaper storage classes over time
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Delete old logs after 1 year to control costs
    expiration {
      days = 365
    }
  }

  rule {
    id     = "manage_error_pages"
    status = "Enabled"

    filter {
      prefix = "error-pages/"
    }

    # Keep error pages indefinitely, but clean up incomplete uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
