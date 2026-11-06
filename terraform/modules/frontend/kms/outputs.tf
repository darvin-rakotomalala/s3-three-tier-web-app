###########################################
## KMS OUTPUTS
###########################################

output "s3_key_arn" {
  description = "KMS key for frontend encryption"
  value       = aws_kms_key.s3_key.arn
}
