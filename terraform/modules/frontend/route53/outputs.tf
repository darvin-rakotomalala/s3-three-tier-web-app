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
