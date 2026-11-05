####################################################
# SNS OUTPUTS
####################################################

output "frontend_sns_topic_arn" {
  description = "SNS topic arn for CloudFront for frontend"
  value       = aws_sns_topic.cloudfront_alerts.arn
}

output "backend_sns_alerts_topic_arn" {
  description = "The Amazon Resource Name (ARN) of the SNS topic used for alerts"
  value       = aws_sns_topic.alerts.arn
}
