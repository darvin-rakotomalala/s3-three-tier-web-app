###########################################
# S3 BUCKET OUTPUTS
###########################################

output "s3_bucket_website_id" {
  description = "Website S3 bucket ID"
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_website_arn" {
  description = "Website S3 bucket ARN"
  value       = aws_s3_bucket.website.arn
}

output "s3_bucket_cloudfront_ops_id" {
  description = "Website S3 bucket ID"
  value       = aws_s3_bucket.cloudfront_ops.id
}

output "s3_bucket_cloudfront_ops_arn" {
  description = "Website S3 bucket ARN"
  value       = aws_s3_bucket.cloudfront_ops.arn
}

output "website_bucket_regional_domain_name" {
  description = "Website bucket regional domain name"
  value       = aws_s3_bucket.website.bucket_regional_domain_name
}

output "cloudfront_ops_bucket_regional_domain_name" {
  description = "CloudFront error page bucket regional domain name"
  value       = aws_s3_bucket.cloudfront_ops.bucket_regional_domain_name
}

output "website_bucket" {
  description = "Website S3 bucket"
  value       = aws_s3_bucket.website.bucket
}

output "cloudfront_ops_bucket" {
  description = "CloudFront error page S3 bucket"
  value       = aws_s3_bucket.cloudfront_ops.bucket
}

output "cloudfront_ops_bucket_domain_name" {
  description = "CloudFront error page S3 bucket domain name"
  value       = aws_s3_bucket.cloudfront_ops.bucket_domain_name
}

output "jar_artifacts_bucket_name" {
  description = "ID of the S3 bucket storing the Spring Boot JAR artifact"
  value       = aws_s3_bucket.jar_artifacts.id
}

output "jar_artifacts_bucket_arn" {
  description = "ARN of the S3 bucket storing the Spring Boot JAR artifact"
  value       = aws_s3_bucket.jar_artifacts.arn
}

output "app_jar_object_id" {
  description = "Reference this in the ASG's depends_on so instances launch after the JAR exists"
  value       = aws_s3_object.app_jar.id
}

#--- Outputs for S3 Bucket and Policy for ALB Logs

output "alb_logs_s3_bucket_id" {
  description = "The name/ID of the S3 bucket storing ALB access logs."
  value       = aws_s3_bucket.alb_logs.id
}

output "alb_logs_s3_bucket_arn" {
  description = "The ARN of the S3 bucket storing ALB access logs."
  value       = aws_s3_bucket.alb_logs.arn
}

output "alb_logs_s3_bucket_domain_name" {
  description = "The bucket domain name of the ALB access logs S3 bucket."
  value       = aws_s3_bucket.alb_logs.bucket_domain_name
}

output "alb_logs_s3_bucket_policy_id" {
  description = "The ID of the S3 bucket policy applied to the ALB access logs bucket."
  value       = aws_s3_bucket_policy.alb_logs.id
}
