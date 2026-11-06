############################################
# CloudWatch Monitoring — ALB (regional) + CloudFront (always us-east-1)
############################################

resource "aws_cloudwatch_log_group" "alb_access_logs" {
  name              = "/aws/alb/spring-boot-alb"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_cloudwatch_key_arn

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb-access-logs"
  })
}

resource "aws_cloudwatch_log_resource_policy" "alb_access_logs" {
  policy_name = "${var.naming_prefix}-alb-log-delivery-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowElbLogDelivery"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.alb_access_logs.arn}:*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.current_account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:${var.current_partition}:logs:${var.primary_region}:${var.current_account_id}:delivery-source:*"
          }
        }
      }
    ]
  })
}

############################################
# CloudWatch Alarms — ALB (native AWS/ApplicationELB metrics)
############################################

resource "aws_cloudwatch_metric_alarm" "alb_5xx_high" {
  alarm_name          = "${var.naming_prefix}-alb-5xx-high"
  alarm_description   = "Alert when target 5XX errors exceed threshold"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 10
  period              = 60
  evaluation_periods  = 5
  treat_missing_data  = "notBreaching"

  dimensions = { LoadBalancer = var.alb_arn_suffix }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb-5xx-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_response_time_high" {
  alarm_name          = "${var.naming_prefix}-alb-response-time-high"
  alarm_description   = "Alert when target response time exceeds 1 second"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  extended_statistic  = "p99"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1
  period              = 60
  evaluation_periods  = 5
  treat_missing_data  = "notBreaching"

  dimensions = { LoadBalancer = var.alb_arn_suffix }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb-response-time-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.naming_prefix}-alb-unhealthy-hosts"
  alarm_description   = "Alert when any target becomes unhealthy"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 60
  evaluation_periods  = 3
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb-unhealthy-hosts"
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_healthy_hosts_low" {
  alarm_name          = "${var.naming_prefix}-alb-healthy-hosts-low"
  alarm_description   = "Alert when healthy hosts drop below 2"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  statistic           = "Minimum"
  comparison_operator = "LessThanThreshold"
  threshold           = 2
  period              = 60
  evaluation_periods  = 3
  treat_missing_data  = "breaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb-healthy-hosts-low"
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_rejected_connections" {
  alarm_name          = "${var.naming_prefix}-alb-rejected-connections"
  alarm_description   = "Alert when the ALB starts rejecting connections (capacity units exhausted)"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "RejectedConnectionCount"
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 60
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  dimensions = { LoadBalancer = var.alb_arn_suffix }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb-rejected-connections"
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_target_connection_errors" {
  alarm_name          = "${var.naming_prefix}-alb-target-connection-errors"
  alarm_description   = "Alert when target connection errors exceed 10/minute"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetConnectionErrorCount"
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 10
  period              = 60
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  dimensions = { LoadBalancer = var.alb_arn_suffix }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb-target-connection-errors"
  })
}

############################################
# CloudWatch Alarms — CloudFront (us-east-1 only)
############################################

resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_rate_high" {
  provider = aws.us_east_1

  alarm_name          = "${var.naming_prefix}-cloudfront-5xx-rate-high"
  alarm_description   = "Alert when CloudFront's 5xx error rate exceeds 5%"
  namespace           = "AWS/CloudFront"
  metric_name         = "5xxErrorRate"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 5
  period              = 60
  evaluation_periods  = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = var.cloudfront_distribution_id
    Region         = "Global"
  }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-cloudfront-5xx-rate-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_rate_high" {
  provider = aws.us_east_1

  alarm_name          = "${var.naming_prefix}-cloudfront-4xx-rate-high"
  alarm_description   = "Alert when CloudFront's 4xx error rate exceeds 10% (client errors, auth failures, etc.)"
  namespace           = "AWS/CloudFront"
  metric_name         = "4xxErrorRate"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 10
  period              = 60
  evaluation_periods  = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = var.cloudfront_distribution_id
    Region         = "Global"
  }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-cloudfront-4xx-rate-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_origin_latency_high" {
  provider = aws.us_east_1

  alarm_name          = "${var.naming_prefix}-cloudfront-origin-latency-high"
  alarm_description   = "Alert when CloudFront's origin (ALB) latency exceeds 2 seconds"
  namespace           = "AWS/CloudFront"
  metric_name         = "OriginLatency"
  extended_statistic  = "p99"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 2000 # milliseconds
  period              = 60
  evaluation_periods  = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = var.cloudfront_distribution_id
    Region         = "Global"
  }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-cloudfront-origin-latency-high"
  })
}

resource "aws_cloudfront_monitoring_subscription" "this" {
  provider        = aws.us_east_1
  distribution_id = var.cloudfront_distribution_id

  monitoring_subscription {
    realtime_metrics_subscription_config {
      realtime_metrics_subscription_status = "Enabled"
    }
  }
}

############################################
# CloudWatch Dashboards
############################################

resource "aws_cloudwatch_dashboard" "alb" {
  dashboard_name = "${var.naming_prefix}-alb-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 8, height = 6,
        properties = {
          title   = "ALB Request Count"
          region  = var.primary_region
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", period = 60 }]]
        }
      },
      {
        type = "metric", x = 8, y = 0, width = 8, height = 6,
        properties = {
          title  = "ALB Target Response Time (p50 / p99)"
          region = var.primary_region
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p50", period = 60, label = "p50" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p99", period = 60, label = "p99" }],
          ]
        }
      },
      {
        type = "metric", x = 16, y = 0, width = 8, height = 6,
        properties = {
          title  = "ALB Healthy vs Unhealthy Hosts"
          region = var.primary_region
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.target_group_arn_suffix, { stat = "Minimum", period = 60, label = "Healthy" }],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.target_group_arn_suffix, { stat = "Maximum", period = 60, label = "Unhealthy" }],
          ]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 8, height = 6,
        properties = {
          title  = "ALB HTTP Status Codes"
          region = var.primary_region
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", period = 60, label = "2XX" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", period = 60, label = "4XX" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", period = 60, label = "5XX" }],
          ]
        }
      },
      {
        type = "metric", x = 8, y = 6, width = 8, height = 6,
        properties = {
          title  = "ALB Rejected Connections & Target Connection Errors"
          region = var.primary_region
          metrics = [
            ["AWS/ApplicationELB", "RejectedConnectionCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", period = 60, label = "Rejected" }],
            ["AWS/ApplicationELB", "TargetConnectionErrorCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", period = 60, label = "Conn Errors" }],
          ]
        }
      },
      {
        type = "log", x = 16, y = 6, width = 8, height = 6,
        properties = {
          title  = "ALB Access Logs (once delivery is enabled)"
          region = var.primary_region
          view   = "table"
          query  = "SOURCE '${aws_cloudwatch_log_group.alb_access_logs.name}' | fields @timestamp, @message | sort @timestamp desc | limit 20"
        }
      },
      {
        type = "metric", x = 0, y = 12, width = 8, height = 6,
        properties = {
          title   = "CloudFront Requests"
          region  = "us-east-1"
          metrics = [["AWS/CloudFront", "Requests", "DistributionId", var.cloudfront_distribution_id, "Region", "Global", { stat = "Sum", period = 60 }]]
        }
      },
      {
        type = "metric", x = 8, y = 12, width = 8, height = 6,
        properties = {
          title  = "CloudFront Error Rates"
          region = "us-east-1"
          metrics = [
            ["AWS/CloudFront", "4xxErrorRate", "DistributionId", var.cloudfront_distribution_id, "Region", "Global", { stat = "Average", period = 60, label = "4xx %" }],
            ["AWS/CloudFront", "5xxErrorRate", "DistributionId", var.cloudfront_distribution_id, "Region", "Global", { stat = "Average", period = 60, label = "5xx %" }],
          ]
        }
      },
      {
        type = "metric", x = 16, y = 12, width = 8, height = 6,
        properties = {
          title   = "CloudFront Origin Latency (p99)"
          region  = "us-east-1"
          metrics = [["AWS/CloudFront", "OriginLatency", "DistributionId", var.cloudfront_distribution_id, "Region", "Global", { stat = "p99", period = 60 }]]
        }
      }
    ]
  })
}
