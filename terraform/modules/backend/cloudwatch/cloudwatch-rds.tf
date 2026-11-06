############################################
# CloudWatch Monitoring for RDS PostgreSQL
############################################

resource "aws_cloudwatch_log_group" "rds_postgresql" {
  name              = "/aws/rds/instance/${var.db_instance_main_identifier}/crud-postgresql"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_cloudwatch_key_arn

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-rds-postgresql-logs"
  })
}

# Metric filter for slow queries (> 1s, matches log_min_duration_statement in 16-rds.tf)
resource "aws_cloudwatch_log_metric_filter" "rds_slow_queries" {
  name           = "${var.naming_prefix}-rds-slow-queries"
  log_group_name = aws_cloudwatch_log_group.rds_postgresql.name
  pattern        = "?duration ?slow"

  metric_transformation {
    name          = "SlowQueryCount"
    namespace     = "${var.naming_prefix}/RDS"
    value         = "1"
    default_value = 0
  }
}

############################################
# Alarms
############################################

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.naming_prefix}-rds-cpu-high"
  alarm_description   = "Alert when RDS CPU exceeds threshold"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.cpu_threshold_percent
  period              = 300
  evaluation_periods  = 3
  treat_missing_data  = "missing"

  dimensions = { DBInstanceIdentifier = var.db_instance_main_identifier }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-rds-cpu-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_freeable_memory_low" {
  alarm_name          = "${var.naming_prefix}-rds-freeable-memory-low"
  alarm_description   = "Critical: freeable memory has dropped below 10% of expected instance-class memory"
  namespace           = "AWS/RDS"
  metric_name         = "FreeableMemory"
  statistic           = "Average"
  comparison_operator = "LessThanThreshold"
  threshold           = local.db_memory_bytes * 0.10
  period              = 300
  evaluation_periods  = 3
  treat_missing_data  = "missing"

  dimensions = { DBInstanceIdentifier = var.db_instance_main_identifier }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-rds-freeable-memory-low"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "${var.naming_prefix}-rds-free-storage-low"
  alarm_description   = "Alert when free storage drops below 5 GB"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Minimum"
  comparison_operator = "LessThanThreshold"
  threshold           = 5 * 1024 * 1024 * 1024 # 5 GB in bytes
  period              = 300
  evaluation_periods  = 2
  treat_missing_data  = "missing"

  dimensions = { DBInstanceIdentifier = var.db_instance_main_identifier }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-rds-free-storage-low"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_disk_queue_depth_high" {
  alarm_name          = "${var.naming_prefix}-rds-disk-queue-depth-high"
  alarm_description   = "Warning: sustained disk queue depth above 20"
  namespace           = "AWS/RDS"
  metric_name         = "DiskQueueDepth"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 20
  period              = 300
  evaluation_periods  = 3
  treat_missing_data  = "notBreaching"

  dimensions = { DBInstanceIdentifier = var.db_instance_main_identifier }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-rds-disk-queue-depth-high"
  })
}

locals {
  # Approximate memory (bytes) per instance class family, used to derive
  # dynamic thresholds (max_connections, freeable-memory %) without a
  # hardcoded standalone variable.
  instance_class_memory_gb = {
    "db.t3.micro"    = 1
    "db.t3.small"    = 2
    "db.t3.medium"   = 4
    "db.t3.large"    = 8
    "db.t4g.micro"   = 1
    "db.t4g.medium"  = 4
    "db.r5.large"    = 16
    "db.r5.xlarge"   = 32
    "db.r5.2xlarge"  = 64
    "db.r6g.large"   = 16
    "db.r6g.xlarge"  = 32
    "db.r6g.2xlarge" = 64
  }

  db_memory_gb    = lookup(local.instance_class_memory_gb, var.db_instance_class, 4)
  db_memory_bytes = local.db_memory_gb * 1024 * 1024 * 1024

  # Mirrors the default RDS PostgreSQL formula: LEAST(DBInstanceClassMemory/9531392, 5000)
  computed_max_connections = min(floor(local.db_memory_bytes / 9531392), 5000)
}

resource "aws_cloudwatch_metric_alarm" "rds_high_connections" {
  alarm_name          = "${var.naming_prefix}-rds-high-connections"
  alarm_description   = "Alert when database connections exceed threshold percentage of the computed max_connections for ${var.db_instance_class}"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"

  threshold          = local.computed_max_connections * (var.connection_threshold_percent / 100)
  period             = 300
  evaluation_periods = 3
  treat_missing_data = "notBreaching"

  dimensions = { DBInstanceIdentifier = var.db_instance_main_identifier }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-rds-high-connections"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_read_write_latency_high" {
  for_each = toset(["ReadLatency", "WriteLatency"])

  alarm_name          = "${var.naming_prefix}-rds-${lower(each.value)}-high"
  alarm_description   = "Warning: sustained ${each.value} above 20ms"
  namespace           = "AWS/RDS"
  metric_name         = each.value
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0.020 # 20ms, in seconds (CloudWatch RDS latency unit)
  period              = 300
  evaluation_periods  = 3
  treat_missing_data  = "notBreaching"

  dimensions = { DBInstanceIdentifier = var.db_instance_main_identifier }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-rds-${lower(each.value)}-high"
  })
}

# CloudWatch Anomaly Detection Alarm for Read Latency
resource "aws_cloudwatch_metric_alarm" "rds_read_latency_anomaly" {
  alarm_name          = "${var.naming_prefix}-rds-read-latency-anomaly"
  alarm_description   = "Alert when Read Latency diverges from its expected dynamic baseline"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = 2
  threshold_metric_id = "e1"
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "m1"
    return_data = "true"
    metric {
      metric_name = "ReadLatency"
      namespace   = "AWS/RDS"
      period      = 300
      stat        = "Average"
      dimensions  = { DBInstanceIdentifier = var.db_instance_main_identifier }
    }
  }

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 3)"
    label       = "ReadLatency (Expected)"
    return_data = "true"
  }

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-rds-read-latency-anomaly"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_slow_query_count_high" {
  alarm_name          = "${var.naming_prefix}-rds-slow-query-count-high"
  alarm_description   = "Alert when slow queries (> 1s) exceed threshold"
  namespace           = aws_cloudwatch_log_metric_filter.rds_slow_queries.metric_transformation[0].namespace
  metric_name         = aws_cloudwatch_log_metric_filter.rds_slow_queries.metric_transformation[0].name
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 10
  period              = 300
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.sns_alerts_topic_arn]
  # ok_actions    = [var.sns_alerts_topic_arn]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-rds-slow-query-count-high"
  })
}

############################################
# CloudWatch Dashboard — RDS
############################################

resource "aws_cloudwatch_dashboard" "rds" {
  dashboard_name = "${var.naming_prefix}-rds-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 8, height = 6,
        properties = {
          title   = "RDS CPU Utilization"
          region  = var.primary_region
          metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_main_identifier, { stat = "Average", period = 300 }]]
        }
      },
      {
        type = "metric", x = 8, y = 0, width = 8, height = 6,
        properties = {
          title   = "RDS Connections"
          region  = var.primary_region
          metrics = [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_instance_main_identifier, { stat = "Average", period = 300 }]]
        }
      },
      {
        type = "metric", x = 16, y = 0, width = 8, height = 6,
        properties = {
          title  = "RDS Read / Write Latency"
          region = var.primary_region
          metrics = [
            ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", var.db_instance_main_identifier, { stat = "Average", period = 300, label = "Read" }],
            ["AWS/RDS", "WriteLatency", "DBInstanceIdentifier", var.db_instance_main_identifier, { stat = "Average", period = 300, label = "Write" }]
          ]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 8, height = 6,
        properties = {
          title   = "RDS Free Storage Space"
          region  = var.primary_region
          metrics = [["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.db_instance_main_identifier, { stat = "Minimum", period = 300 }]]
        }
      },
      {
        type = "metric", x = 8, y = 6, width = 8, height = 6,
        properties = {
          title  = "ReadIOPS / WriteIOPS"
          region = var.primary_region
          metrics = [
            ["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", var.db_instance_main_identifier, { stat = "Average", period = 300, label = "ReadIOPS" }],
            ["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", var.db_instance_main_identifier, { stat = "Average", period = 300, label = "WriteIOPS" }]
          ]
        }
      },
      {
        type = "metric", x = 16, y = 6, width = 8, height = 6,
        properties = {
          title   = "Estimated Daily Spend - RDS (Billing metrics must be enabled in Account Settings)"
          region  = "us-east-1"
          metrics = [["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonRDS", "Currency", "USD", { stat = "Maximum", period = 86400 }]]
        }
      }
    ]
  })
}
