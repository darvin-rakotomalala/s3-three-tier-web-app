###########################################
## CLOUDWATCH FOR CLOUDFRONT
###########################################

resource "aws_cloudwatch_dashboard" "cloudfront" {
  dashboard_name = "${var.naming_prefix}-frontend-cf-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "CacheHitRate", "DistributionId", var.frontend_cf_distribution_id],
            [".", "OriginLatency", ".", "."],
            [".", "Requests", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront Performance Metrics"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "4xxErrorRate", "DistributionId", var.frontend_cf_distribution_id],
            [".", "5xxErrorRate", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Error Rates"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "BytesDownloaded", "DistributionId", var.frontend_cf_distribution_id],
            [".", "BytesUploaded", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Data Transfer"
          period  = 300
          stat    = "Sum"
        }
      }
    ]
  })
}

# CloudWatch Alarms------------------
resource "aws_cloudwatch_metric_alarm" "frontend_cf_high_4xx_error_rate" {
  alarm_name          = "${var.naming_prefix}-frontend-cf-high-4xx-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "Frontend CloudFront 4xx error rate is above 5%"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.frontend_sns_topic_arn]

  dimensions = {
    DistributionId = var.frontend_cf_distribution_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-frontend-cf-4xx-error-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "frontend_cf_high_5xx_error_rate" {
  alarm_name          = "${var.naming_prefix}-frontend-cf-high-5xx-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Frontend CloudFront 5xx error rate is above 1%"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.frontend_sns_topic_arn]

  dimensions = {
    DistributionId = var.frontend_cf_distribution_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-frontend-cf-5xx-error-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "frontend_cf_low_cache_hit_rate" {
  alarm_name          = "${var.naming_prefix}-frontend-cf-low-cache-hit-rate"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CacheHitRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Frontend CloudFront cache hit rate is below 80%"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.frontend_sns_topic_arn]

  dimensions = {
    DistributionId = var.frontend_cf_distribution_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-frontend-cf-cache-hit-rate-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "frontend_cf_high_origin_latency" {
  alarm_name          = "${var.naming_prefix}-frontend-cf-high-origin-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "OriginLatency"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "3000" # 3 seconds
  alarm_description   = "Frontend CloudFront origin latency is above 3 seconds"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.frontend_sns_topic_arn]

  dimensions = {
    DistributionId = var.frontend_cf_distribution_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-frontend-cf-origin-latency-alarm"
  })
}
