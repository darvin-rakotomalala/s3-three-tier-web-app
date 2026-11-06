###########################################
# S3 BUCKET OUTPUTS
###########################################

output "frontend_s3_bucket_website_id" {
  description = "Website S3 bucket ID"
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_website_arn" {
  description = "Website S3 bucket ARN"
  value       = aws_s3_bucket.website.arn
}

output "frontend_s3_bucket_cloudfront_ops_id" {
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
