###########################################
## CLOUDFRONT OUTPUTS
###########################################

output "frontend_cf_website_domain_name" {
  description = "CloudFront domain name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "frontend_cf_website_hosted_zone_id" {
  description = "CloudFront hosted zone id"
  value       = aws_cloudfront_distribution.website.hosted_zone_id
}

output "frontend_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.website.id
}

output "frontend_distribution_arn" {
  description = "CloudFront Distribution ARN"
  value       = aws_cloudfront_distribution.website.arn
}

output "frontend_distribution_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "frontend_distribution_hosted_zone_id" {
  description = "CloudFront Distribution Hosted Zone ID"
  value       = aws_cloudfront_distribution.website.hosted_zone_id
}

output "frontend_website_origin_access_control_id" {
  description = "Website Origin Access Control ID"
  value       = aws_cloudfront_origin_access_control.website.id
}

output "error_pages_origin_access_control_id" {
  description = "Error pages Origin Access Control ID"
  value       = aws_cloudfront_origin_access_control.error_pages.id
}

output "backend_cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution (e.g., E1A2B3C4D5E6F7)."
  value       = aws_cloudfront_distribution.backend.id
}

output "backend_cloudfront_domain_name" {
  description = "CloudFront's own *.cloudfront.net domain name (the public DNS records alias to this)"
  value       = aws_cloudfront_distribution.backend.domain_name
}

output "backend_cloudfront_hosted_zone_id" {
  description = "Route 53 hosted zone ID of the CloudFront distribution (use as the alias target zone_id)"
  value       = aws_cloudfront_distribution.backend.hosted_zone_id
}
