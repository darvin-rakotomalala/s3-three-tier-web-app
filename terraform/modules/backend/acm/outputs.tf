############################################
# ACM OUTPUTS
############################################

output "acm_origin_certificate_arn" {
  description = "ARN of the validated regional ACM certificate used by the ALB HTTPS listener"
  value       = aws_acm_certificate_validation.origin.certificate_arn
}

output "acm_cloudfront_certificate_arn" {
  description = "ARN of the validated us-east-1 ACM certificate used by CloudFront's viewer TLS"
  value       = aws_acm_certificate_validation.cloudfront.certificate_arn
}
