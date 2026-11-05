###########################################
# ACM CERTIFICATE OUTPUTS
###########################################

output "frontend_acm_certificate_arn" {
  description = "ACM certificate validation ARN"
  value       = aws_acm_certificate_validation.website.certificate_arn
}

output "backend_acm_origin_certificate_arn" {
  description = "ARN of the validated regional ACM certificate used by the ALB HTTPS listener"
  value       = aws_acm_certificate_validation.origin.certificate_arn
}

output "backend_acm_cloudfront_certificate_arn" {
  description = "ARN of the validated us-east-1 ACM certificate used by CloudFront's viewer TLS"
  value       = aws_acm_certificate_validation.cloudfront.certificate_arn
}
