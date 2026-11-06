###########################################
## CLOUDFRONT OUTPUTS
###########################################

output "cf_website_domain_name" {
  description = "CloudFront domain name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "cf_website_hosted_zone_id" {
  description = "CloudFront hosted zone id"
  value       = aws_cloudfront_distribution.website.hosted_zone_id
}

output "distribution_id" {
  description = "CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.website.id
}

output "distribution_arn" {
  description = "CloudFront Distribution ARN"
  value       = aws_cloudfront_distribution.website.arn
}

output "distribution_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "distribution_hosted_zone_id" {
  description = "CloudFront Distribution Hosted Zone ID"
  value       = aws_cloudfront_distribution.website.hosted_zone_id
}

output "website_origin_access_control_id" {
  description = "Website Origin Access Control ID"
  value       = aws_cloudfront_origin_access_control.website.id
}

output "error_pages_origin_access_control_id" {
  description = "Error pages Origin Access Control ID"
  value       = aws_cloudfront_origin_access_control.error_pages.id
}
