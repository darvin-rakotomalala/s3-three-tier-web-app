###########################################
## CLOUDWATCH FOR CLOUDFRONT OUTPUTS
###########################################

output "cloudfront_dashboard_arn" {
  description = "The Amazon Resource Name (ARN) of the CloudWatch dashboard."
  value       = aws_cloudwatch_dashboard.cloudfront.dashboard_arn
}

output "cloudfront_dashboard_name" {
  description = "The name of the CloudWatch dashboard."
  value       = aws_cloudwatch_dashboard.cloudfront.dashboard_name
}

# Alarm ARNs
output "alarm_high_4xx_error_rate_arn" {
  description = "The ARN of the High 4xx Error Rate alarm."
  value       = aws_cloudwatch_metric_alarm.high_4xx_error_rate.arn
}

output "alarm_high_5xx_error_rate_arn" {
  description = "The ARN of the High 5xx Error Rate alarm."
  value       = aws_cloudwatch_metric_alarm.high_5xx_error_rate.arn
}

output "alarm_low_cache_hit_rate_arn" {
  description = "The ARN of the Low Cache Hit Rate alarm."
  value       = aws_cloudwatch_metric_alarm.low_cache_hit_rate.arn
}

output "alarm_high_origin_latency_arn" {
  description = "The ARN of the High Origin Latency alarm."
  value       = aws_cloudwatch_metric_alarm.high_origin_latency.arn
}

# Alarm Names
output "alarm_names" {
  description = "Map of created CloudWatch metric alarm names."
  value = {
    high_4xx_error_rate = aws_cloudwatch_metric_alarm.high_4xx_error_rate.alarm_name
    high_5xx_error_rate = aws_cloudwatch_metric_alarm.high_5xx_error_rate.alarm_name
    low_cache_hit_rate  = aws_cloudwatch_metric_alarm.low_cache_hit_rate.alarm_name
    high_origin_latency = aws_cloudwatch_metric_alarm.high_origin_latency.alarm_name
  }
}
