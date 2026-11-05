###########################################
## KMS OUTPUTS
###########################################

output "frontend_s3_key_arn" {
  description = "KMS key for frontend encryption"
  value       = aws_kms_key.s3_key.arn
}

output "kms_rds_key_arn" {
  description = "ARN of the KMS key used for RDS encryption"
  value       = aws_kms_key.rds.arn
}

output "kms_secrets_key_arn" {
  description = "ARN of the KMS key used for Secrets Manager encryption"
  value       = aws_kms_key.secrets.arn
}

output "kms_cloudwatch_key_arn" {
  description = "ARN of the KMS key used for CloudWatch Logs / SNS encryption"
  value       = aws_kms_key.cloudwatch.arn
}

output "kms_cloudwatch_key_id" {
  description = "ID of the KMS key used for CloudWatch Logs / SNS encryption"
  value       = aws_kms_key.cloudwatch.id
}

output "kms_key_jar_artifacts_arn" {
  description = "ARN of the KMS key used for JAR artifacts"
  value       = aws_kms_key.jar_artifacts.arn
}

output "ebs_kms_key_arn" {
  description = "ARN of the KMS key used for EBS encryption"
  value       = aws_kms_key.ebs.arn
}

output "ec2_linux_kms_key_id" {
  description = "ID of the custom KMS key"
  value       = aws_kms_key.custom_kms_key.id
}

output "ec2_linux_kms_key_arn" {
  description = "ARN of the custom KMS key"
  value       = aws_kms_key.custom_kms_key.arn
}

output "ec2_linux_kms_key_rotation_enabled" {
  description = "Whether automatic key rotation is enabled"
  value       = aws_kms_key.custom_kms_key.enable_key_rotation
}

output "ec2_linux_kms_alias_name" {
  description = "Name of the KMS alias"
  value       = aws_kms_alias.key.name
}

output "ec2_linux_kms_alias_arn" {
  description = "ARN of the KMS alias"
  value       = aws_kms_alias.key.arn
}

output "ec2_linux_kms_key_policy_id" {
  description = "ID of the KMS key policy resource"
  value       = aws_kms_key_policy.encrypt_app.id
}
