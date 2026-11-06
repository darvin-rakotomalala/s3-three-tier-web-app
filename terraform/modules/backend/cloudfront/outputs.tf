############################################
# CF OUTPUTS
############################################

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution (e.g., E1A2B3C4D5E6F7)."
  value       = aws_cloudfront_distribution.app.id
}

output "cloudfront_domain_name" {
  description = "CloudFront's own *.cloudfront.net domain name (the public DNS records alias to this)"
  value       = aws_cloudfront_distribution.app.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "Route 53 hosted zone ID of the CloudFront distribution (use as the alias target zone_id)"
  value       = aws_cloudfront_distribution.app.hosted_zone_id
}
