############################################
# S3 Bucket — JAR Artifacts ONLY
############################################

resource "aws_s3_bucket" "jar_artifacts" {
  bucket        = var.jar_bucket_name
  force_destroy = var.environment == "prod" ? false : true

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-jar-artifacts"
  })
}

resource "aws_s3_bucket_public_access_block" "jar_artifacts" {
  bucket                  = aws_s3_bucket.jar_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "jar_artifacts" {
  bucket = aws_s3_bucket.jar_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_jar_artifacts_arn
      sse_algorithm     = "aws:kms"
    }
    # Reduces KMS API request volume during rapid ASG scale-out events
    bucket_key_enabled = true
  }
}

############################################
# S3 Bucket Policy (Enforce SSE-KMS & TLS-only access)
############################################

resource "aws_s3_bucket_policy" "jar_artifacts" {
  bucket = aws_s3_bucket.jar_artifacts.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2InstanceRoleReadOnly"
        Effect = "Allow"
        Principal = {
          AWS = var.ec2_app_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.jar_artifacts.arn,
          "${aws_s3_bucket.jar_artifacts.arn}/*"
        ]
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.jar_artifacts.arn,
          "${aws_s3_bucket.jar_artifacts.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.jar_artifacts.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })
}

############################################
# Initial JAR upload (seeded during terraform apply)
############################################

locals {
  jar_path = "${path.module}/${var.jar_local_path}"
}

resource "aws_s3_object" "app_jar" {
  bucket = aws_s3_bucket.jar_artifacts.id
  key    = var.jar_object_key
  source = local.jar_path

  # The bucket policy denies uploads that are not SSE-KMS
  server_side_encryption = "aws:kms"
  kms_key_id             = var.kms_key_jar_artifacts_arn
  bucket_key_enabled     = true

  # Re-upload if the local file changes - ignored below so the workflow owns updates
  source_hash = filemd5(local.jar_path)

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-app-jar"
  })

  lifecycle {
    precondition {
      condition     = fileexists(local.jar_path)
      error_message = "JAR not found at ${local.jar_path}. Build it first (mvn clean package) or set jar_local_path."
    }

    # Terraform only seeds the JAR. After that, deploy_app.yml overwrites the same key
    # on every release, and Terraform must not revert it on the next apply.
    ignore_changes = [source_hash]
  }

  depends_on = [
    aws_s3_bucket_policy.jar_artifacts,
    aws_s3_bucket_server_side_encryption_configuration.jar_artifacts,
  ]
}
