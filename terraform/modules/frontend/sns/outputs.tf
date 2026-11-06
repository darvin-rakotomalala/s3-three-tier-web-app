####################################################
# SNS OUTPUTS
####################################################

output "sns_topic_arn" {
  description = "SNS topic arn"
  value       = aws_sns_topic.cloudfront_alerts.arn
}
