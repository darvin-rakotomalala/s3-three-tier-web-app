############################################
# CloudWatch Monitoring for the EC2 Application Tier
############################################

resource "aws_cloudwatch_log_group" "app_tier" {
  name              = "/aws/ec2/spring-boot-backend-app-tier"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_cloudwatch_key_arn

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-app-tier-logs"
  })
}

############################################
# Metric Filters: extract ERROR / WARN counts from application logs
############################################

resource "aws_cloudwatch_log_metric_filter" "app_error" {
  name           = "${var.naming_prefix}-app-error-count"
  log_group_name = aws_cloudwatch_log_group.app_tier.name
  pattern        = "?ERROR ?Error ?error"

  metric_transformation {
    name          = "ApplicationErrorCount"
    namespace     = "${var.naming_prefix}/AppTier"
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "app_warning" {
  name           = "${var.naming_prefix}-app-warning-count"
  log_group_name = aws_cloudwatch_log_group.app_tier.name
  pattern        = "?WARN ?Warning ?warning"

  metric_transformation {
    name          = "ApplicationWarningCount"
    namespace     = "${var.naming_prefix}/AppTier"
    value         = "1"
    default_value = 0
  }
}

############################################
# CloudWatch Alarms — EC2 App Tier (ASG-wide, fleet-size agnostic)
############################################

resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  alarm_name          = "${var.naming_prefix}-asg-cpu-high"
  alarm_description   = "Alert when average fleet CPU exceeds 80% for 5 consecutive minutes"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  period              = 60
  evaluation_periods  = 5
  treat_missing_data  = "missing"

  dimensions = { AutoScalingGroupName = var.app_autoscaling_group_name }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-asg-cpu-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "asg_status_check_failed" {
  alarm_name          = "${var.naming_prefix}-asg-status-check-failed"
  alarm_description   = "Alert when any instance in the fleet fails EC2 status checks"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  statistic           = "Maximum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 60
  evaluation_periods  = 2
  treat_missing_data  = "missing"

  dimensions = { AutoScalingGroupName = var.app_autoscaling_group_name }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-asg-status-check-failed"
  })
}

resource "aws_cloudwatch_metric_alarm" "asg_memory_high" {
  alarm_name          = "${var.naming_prefix}-asg-memory-high"
  alarm_description   = "Alert when average fleet memory usage exceeds 90%"
  namespace           = "${var.naming_prefix}/EC2"
  metric_name         = "mem_used_percent"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 90
  period              = 60
  evaluation_periods  = 5
  treat_missing_data  = "missing"

  dimensions = { AutoScalingGroupName = var.app_autoscaling_group_name }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-asg-memory-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "asg_disk_high" {
  alarm_name          = "${var.naming_prefix}-asg-disk-high"
  alarm_description   = "Alert when average fleet root-volume disk usage exceeds 85%"
  namespace           = "${var.naming_prefix}/EC2"
  metric_name         = "disk_used_percent"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 85
  period              = 60
  evaluation_periods  = 5
  treat_missing_data  = "missing"

  dimensions = { AutoScalingGroupName = var.app_autoscaling_group_name, path = "/" }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-asg-disk-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "asg_low_healthy_hosts" {
  alarm_name          = "${var.naming_prefix}-asg-low-in-service-instances"
  alarm_description   = "Alert when fewer than 2 instances are InService in the ASG"
  namespace           = "AWS/AutoScaling"
  metric_name         = "GroupInServiceInstances"
  statistic           = "Minimum"
  comparison_operator = "LessThanThreshold"
  threshold           = 2
  period              = 60
  evaluation_periods  = 3
  treat_missing_data  = "breaching"

  dimensions = { AutoScalingGroupName = var.app_autoscaling_group_name }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-asg-low-in-service-instances"
  })
}

resource "aws_cloudwatch_metric_alarm" "app_error_count_high" {
  alarm_name          = "${var.naming_prefix}-app-error-count-high"
  alarm_description   = "This metric monitors application error logs"
  namespace           = aws_cloudwatch_log_metric_filter.app_error.metric_transformation[0].namespace
  metric_name         = aws_cloudwatch_log_metric_filter.app_error.metric_transformation[0].name
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 10
  period              = 300
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-app-error-count-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "app_warning_count_high" {
  alarm_name          = "${var.naming_prefix}-app-warning-count-high"
  alarm_description   = "This metric monitors application warning logs"
  namespace           = aws_cloudwatch_log_metric_filter.app_warning.metric_transformation[0].namespace
  metric_name         = aws_cloudwatch_log_metric_filter.app_warning.metric_transformation[0].name
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 25
  period              = 300
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-app-warning-count-high"
  })
}

# Composite Alarm — overall application health status
resource "aws_cloudwatch_composite_alarm" "app_tier_health" {
  alarm_name        = "${var.naming_prefix}-app-tier-overall-health"
  alarm_description = "Composite: fires if CPU/memory/status-checks/error-rate breach or in-service capacity drops"

  alarm_rule = join(" OR ", [
    "ALARM(\"${aws_cloudwatch_metric_alarm.asg_cpu_high.alarm_name}\")",
    "ALARM(\"${aws_cloudwatch_metric_alarm.asg_status_check_failed.alarm_name}\")",
    "ALARM(\"${aws_cloudwatch_metric_alarm.asg_low_healthy_hosts.alarm_name}\")",
    "ALARM(\"${aws_cloudwatch_metric_alarm.app_error_count_high.alarm_name}\")",
  ])

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-app-tier-overall-health"
  })
}

############################################
# CloudWatch Dashboard — EC2 App Tier (ASG + fleet-wide metrics)
############################################

resource "aws_cloudwatch_dashboard" "app_tier" {
  dashboard_name = "${var.naming_prefix}-app-tier-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 8, height = 6,
        properties = {
          title   = "EC2 CPU Utilization (ASG average)"
          region  = var.primary_region
          metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.app_autoscaling_group_name, { stat = "Average", period = 60 }]]
        }
      },
      {
        type = "metric", x = 8, y = 0, width = 8, height = 6,
        properties = {
          title  = "Memory & Disk Usage (fleet average)"
          region = var.primary_region
          metrics = [
            ["${var.naming_prefix}/EC2", "mem_used_percent", "AutoScalingGroupName", var.app_autoscaling_group_name, { stat = "Average", period = 60, label = "mem" }],
            ["${var.naming_prefix}/EC2", "disk_used_percent", "AutoScalingGroupName", var.app_autoscaling_group_name, "path", "/", { stat = "Average", period = 60, label = "disk" }],
          ]
        }
      },
      {
        type = "metric", x = 16, y = 0, width = 8, height = 6,
        properties = {
          title   = "Network Throughput"
          region  = var.primary_region
          metrics = [["AWS/EC2", "NetworkIn", "AutoScalingGroupName", var.app_autoscaling_group_name, { stat = "Sum", period = 60 }]]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 8, height = 6,
        properties = {
          title  = "Application Log Metrics (ERROR / WARN)"
          region = var.primary_region
          metrics = [
            ["${var.naming_prefix}/AppTier", "ApplicationErrorCount", { stat = "Sum", period = 300, label = "ERROR" }],
            ["${var.naming_prefix}/AppTier", "ApplicationWarningCount", { stat = "Sum", period = 300, label = "WARN" }],
          ]
        }
      },
      {
        type = "log", x = 8, y = 6, width = 16, height = 6,
        properties = {
          title  = "Recent Error Logs"
          region = var.primary_region
          view   = "table"
          query  = "SOURCE '${aws_cloudwatch_log_group.app_tier.name}' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20"
        }
      },
      {
        type = "metric", x = 0, y = 12, width = 8, height = 6,
        properties = {
          title   = "Disk I/O"
          region  = var.primary_region
          metrics = [["AWS/EC2", "DiskReadBytes", "AutoScalingGroupName", var.app_autoscaling_group_name, { stat = "Sum", period = 60 }]]
        }
      },
      {
        type = "metric", x = 8, y = 12, width = 8, height = 6,
        properties = {
          title  = "In-Service Instance Count (dynamic scaling)"
          region = var.primary_region
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", var.app_autoscaling_group_name, { stat = "Average", period = 60, label = "InService" }],
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", var.app_autoscaling_group_name, { stat = "Average", period = 60, label = "Desired" }],
          ]
        }
      },
      {
        type = "metric", x = 16, y = 12, width = 8, height = 6,
        properties = {
          title   = "Status Check Failures"
          region  = var.primary_region
          metrics = [["AWS/EC2", "StatusCheckFailed", "AutoScalingGroupName", var.app_autoscaling_group_name, { stat = "Maximum", period = 60 }]]
        }
      },
      {
        type = "metric", x = 0, y = 18, width = 12, height = 6,
        properties = {
          title  = "ALB Request Rate & Target Response Time (p50/p99)"
          region = var.primary_region
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", period = 60, label = "Requests" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p50", period = 60, label = "p50" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p99", period = 60, label = "p99" }],
          ]
        }
      },
      {
        type = "metric", x = 12, y = 18, width = 12, height = 6,
        properties = {
          title   = "Estimated Daily Spend — EC2 (Billing metrics must be enabled in Account Settings)"
          region  = "us-east-1"
          metrics = [["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonEC2", "Currency", "USD", { stat = "Maximum", period = 86400 }]]
        }
      }
    ]
  })
}
