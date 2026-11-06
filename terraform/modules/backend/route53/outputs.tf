############################################
# OUTPUTS
############################################

output "route53_public_record_fqdns" {
  description = "Public DNS names that resolve to CloudFront"
  value = [
    aws_route53_record.api_alias.fqdn,
  ]
}

output "route53_origin_record_fqdn" {
  description = "Internal DNS name that resolves to the ALB (CloudFront's origin only — not for public use)"
  value       = aws_route53_record.origin_alias.fqdn
}

output "origin_record_name" {
  description = "FQDN of the Route 53 alias record pointing at the ALB (CloudFront's origin hostname)"
  value       = aws_route53_record.origin_alias.name
}
