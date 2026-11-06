############################################
# CLOUDWATCH OUTPUTS
############################################

output "cloudwatch_dashboards" {
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
