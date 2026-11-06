####################################################
# SNS Topic for notifications/alerts
####################################################

resource "aws_sns_topic" "cloudfront_alerts" {
  name = "${var.naming_prefix}-serverless-web-application-alerts"

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-serverless-web-application-alerts"
  })
}

resource "aws_sns_topic_subscription" "email_subscriptions" {
  for_each  = toset(var.email_subscriptions)
  topic_arn = aws_sns_topic.cloudfront_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}
