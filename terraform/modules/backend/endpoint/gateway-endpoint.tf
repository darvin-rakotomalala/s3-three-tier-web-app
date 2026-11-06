############################################
# Gateway VPC Endpoint for S3
# Routes S3 traffic from the app tier through the endpoint instead of
# through the NAT Gateway, and restricts access to only the bucket this
# workload needs.
############################################

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.primary_region}.s3"
  vpc_endpoint_type = "Gateway"

  # Route S3 traffic from every application-tier route table (one per AZ)
  route_table_ids = var.app_route_table_ids

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowScopedS3Buckets"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.jar_artifacts_bucket_arn,
          "${var.jar_artifacts_bucket_arn}/*"
        ]
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-vpce-s3"
  })
}
