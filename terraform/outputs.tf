#########################################################
# MAIN OUTPUTS
#########################################################

output "iam_role_terraform_execution_arn" {
  description = "IAM role terraform execution ARN"
  value       = module.back_iam.iam_role_terraform_execution_arn
}

output "frontend_cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = module.front_cloudfront.distribution_id
}

output "frontend_cloudfront_distribution_arn" {
  description = "CloudFront Distribution ARN"
  value       = module.front_cloudfront.distribution_arn
}

output "frontend_cloudfront_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = module.front_cloudfront.distribution_domain_name
}

output "frontend_cloudfront_hosted_zone_id" {
  description = "CloudFront Distribution Hosted Zone ID"
  value       = module.front_cloudfront.distribution_hosted_zone_id
}

output "frontend_website_bucket_name" {
  description = "S3 Bucket Name for website content"
  value       = module.front_s3.website_bucket
}

output "frontend_website_bucket_arn" {
  description = "S3 Bucket ARN for website content"
  value       = module.front_s3.s3_bucket_website_arn
}

output "frontend_logs_bucket_name" {
  description = "S3 Bucket Name for CloudFront logs"
  value       = module.front_s3.cloudfront_ops_bucket
}

output "frontend_route53_zone_id" {
  description = "Route53 Hosted Zone ID"
  value       = data.aws_route53_zone.existing.zone_id
}

output "frontend_acm_certificate_arn" {
  description = "ACM Certificate ARN"
  value       = module.front_acm.acm_certificate_arn
}

output "frontend_waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = module.front_waf.cf_waf_acl_arn
}

output "frontend_website_origin_access_control_id" {
  description = "Origin Access Control ID"
  value       = module.front_cloudfront.website_origin_access_control_id
}

output "frontend_error_pages_origin_access_control_id" {
  description = "Error pages Origin Access Control ID"
  value       = module.front_cloudfront.error_pages_origin_access_control_id
}

output "frontend_website_url" {
  description = "Website URL"
  value       = "https://${var.domain_name}"
}

output "frontend_www_website_url" {
  description = "WWW Website URL"
  value       = "https://www.${var.domain_name}"
}

output "frontend_ds_record" {
  description = "DS record to add to your domain registrar"
  value       = module.front_route53.ds_record_dnssec
}

output "frontend_ksk_status" {
  description = "Current status of the Key Signing Key"
  value       = module.front_route53.ksk_status_dnssec
}

output "frontend_ds_record_KSK" {
  description = "Formatted DS record for registrar"
  value       = module.front_route53.ds_record_KSK
}

###---- BACKEND PROVISIONING

output "backend_ec2_instance_id" {
  description = "Instance ID of EC2-SSM-SERVER (use this to start an SSM session)"
  value       = module.back_autoscaling-group.ec2_instance_ids
}

output "backend_app_autoscaling_group_name" {
  description = "Name of the Auto Scaling Group managing the web fleet"
  value       = module.back_autoscaling-group.app_autoscaling_group_name
}

output "backend_db_credentials_secret_name" {
  description = "Name of the Secrets Manager secret holding the RDS master credentials"
  value       = module.back_secrets.db_credentials_secret_name
}

output "backend_kms_key_jar_artifacts_arn" {
  description = "ARN of the KMS key used for JAR artifacts"
  value       = module.back_kms.kms_key_jar_artifacts_arn
}

output "backend_rds_endpoint" {
  description = "Connection endpoint (host:port) for the RDS primary"
  value       = module.back_rds.rds_endpoint
}

locals {
  # Resolves the first InService instance in the ASG when the command is executed
  ssm_target_lookup = "$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${module.back_autoscaling-group.app_autoscaling_group_name} --region ${var.primary_region} --query 'AutoScalingGroups[0].Instances[?LifecycleState==`InService`].InstanceId | [0]' --output text)"
}

output "backend_ssm_connect_command" {
  description = "AWS CLI command to open a Session Manager shell on an instance in the ASG"
  value       = "aws ssm start-session --target ${local.ssm_target_lookup} --region ${var.primary_region}"
}

output "backend_ssm_port_forward_command" {
  description = "AWS CLI command to open an SSM port-forwarding session from your laptop to the RDS primary, via a private ASG instance"
  value       = "aws ssm start-session --target ${local.ssm_target_lookup} --region ${var.primary_region} --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters '{\"host\":[\"${module.back_rds.rds_address}\"],\"portNumber\":[\"5432\"],\"localPortNumber\":[\"4898\"]}'"
}
