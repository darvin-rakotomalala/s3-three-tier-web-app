###########################################
## ROUTE 53 OUTPUTS
###########################################

output "ds_record_KSK" {
  description = "Formatted DS record for registrar"
  value = format("%s %s %s %s",
    aws_route53_key_signing_key.main.key_tag,
    aws_route53_key_signing_key.main.signing_algorithm_mnemonic,
    aws_route53_key_signing_key.main.digest_algorithm_mnemonic,
    aws_route53_key_signing_key.main.digest_value
  )
}

output "ds_record_dnssec" {
  description = "DS record to add to your domain registrar"
  value       = aws_route53_key_signing_key.main.ds_record
}

output "ksk_status_dnssec" {
  description = "Current status of the Key Signing Key"
  value       = aws_route53_key_signing_key.main.status
}

output "backend_route53_public_record_fqdns" {
  description = "Public DNS names that resolve to CloudFront"
  value = [
    aws_route53_record.api_alias.fqdn,
  ]
}

output "backend_route53_origin_record_fqdn" {
  description = "Internal DNS name that resolves to the ALB (CloudFront's origin only — not for public use)"
  value       = aws_route53_record.origin_alias.fqdn
}

output "backend_origin_record_name" {
  description = "FQDN of the Route 53 alias record pointing at the ALB (CloudFront's origin hostname)"
  value       = aws_route53_record.origin_alias.name
}
