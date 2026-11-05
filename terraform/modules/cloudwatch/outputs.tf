###########################################
## CLOUDWATCH FOR CLOUDFRONT OUTPUTS
###########################################

output "frontend_cloudfront_dashboard_arn" {
  description = "The Amazon Resource Name (ARN) of the CloudWatch dashboard."
  value       = aws_cloudwatch_dashboard.cloudfront.dashboard_arn
}

output "frontend_cloudfront_dashboard_name" {
  description = "The name of the CloudWatch dashboard."
  value       = aws_cloudwatch_dashboard.cloudfront.dashboard_name
}

# Alarm ARNs
output "frontend_alarm_high_4xx_error_rate_arn" {
  description = "The ARN of the High 4xx Error Rate alarm."
  value       = aws_cloudwatch_metric_alarm.frontend_cf_high_4xx_error_rate.arn
}

output "frontend_alarm_high_5xx_error_rate_arn" {
  description = "The ARN of the High 5xx Error Rate alarm."
  value       = aws_cloudwatch_metric_alarm.frontend_cf_high_5xx_error_rate.arn
}

output "frontend_alarm_low_cache_hit_rate_arn" {
  description = "The ARN of the Low Cache Hit Rate alarm."
  value       = aws_cloudwatch_metric_alarm.frontend_cf_low_cache_hit_rate.arn
}

output "frontend_alarm_high_origin_latency_arn" {
  description = "The ARN of the High Origin Latency alarm."
  value       = aws_cloudwatch_metric_alarm.frontend_cf_high_origin_latency.arn
}

# Alarm Names
output "frontend_alarm_names" {
  description = "Map of created CloudWatch metric alarm names."
  value = {
    high_4xx_error_rate = aws_cloudwatch_metric_alarm.frontend_cf_high_4xx_error_rate.alarm_name
    high_5xx_error_rate = aws_cloudwatch_metric_alarm.frontend_cf_high_5xx_error_rate.alarm_name
    low_cache_hit_rate  = aws_cloudwatch_metric_alarm.frontend_cf_low_cache_hit_rate.alarm_name
    high_origin_latency = aws_cloudwatch_metric_alarm.frontend_cf_high_origin_latency.alarm_name
  }
}

output "backend_cloudwatch_dashboards" {
  description = "Names of the CloudWatch dashboards created by this stack"
  value = [
    aws_cloudwatch_dashboard.alb.dashboard_name,
    aws_cloudwatch_dashboard.app_tier.dashboard_name,
    aws_cloudwatch_dashboard.rds.dashboard_name,
  ]
}

output "alb_access_log_group_name" {
  description = "Name of the CloudWatch log group that receives ALB access logs"
  value       = aws_cloudwatch_log_group.alb_access_logs.name
}

output "ec2_access_log_group_name" {
  description = "Name of the CloudWatch log group for the EC2 app tier (web fleet) logs"
  value       = aws_cloudwatch_log_group.app_tier.name
}

output "ec2_access_log_group_arn" {
  description = "ARN of the CloudWatch log group for the EC2 app tier (web fleet) logs"
  value       = aws_cloudwatch_log_group.app_tier.arn
}

output "ec2_linux_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.logs.name
}

output "ec2_linux_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.logs.arn
}

output "ec2_linux_log_group_retention_in_days" {
  description = "Retention period (in days) configured on the log group"
  value       = aws_cloudwatch_log_group.logs.retention_in_days
}

output "ec2_linux_log_group_kms_key_id" {
  description = "KMS key ARN used to encrypt the log group"
  value       = aws_cloudwatch_log_group.logs.kms_key_id
}
