###########################################
# ACM certificate OUTPUTS
###########################################

output "acm_certificate_arn" {
  description = "ACM certificate validation ARN"
  value       = aws_acm_certificate_validation.website.certificate_arn
}
