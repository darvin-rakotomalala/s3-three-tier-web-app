############################################
# ASG
############################################

resource "aws_autoscaling_group" "web_fleet" {
  name                = "${var.naming_prefix}-web-fleet-asg"
  vpc_zone_identifier = var.app_subnet_ids
  target_group_arns   = [var.alb_target_group_arn]

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  health_check_type         = "ELB"
  health_check_grace_period = 180 # Tuned to this application's ~90s startup time plus margin

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = var.app_launch_template_id
        version            = var.launch_template_latest_version
      }

      dynamic "override" {
        for_each = var.instance_type_overrides
        content {
          instance_type = override.value
        }
      }
    }

    instances_distribution {
      on_demand_base_capacity                  = var.on_demand_base_capacity
      on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base
      spot_allocation_strategy                 = "capacity-optimized"
    }
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 120
      skip_matching          = true
    }
  }

  dynamic "tag" {
    for_each = merge(var.common_tags, { Name = "${var.naming_prefix}-web-fleet" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_policy" "target_tracking_requests" {
  name                      = "${var.naming_prefix}-target-tracking-requests"
  autoscaling_group_name    = aws_autoscaling_group.web_fleet.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 120

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = var.alb_target_group_resource_label
    }
    target_value = 1000 # Adjust as you need
  }
}

# Scales on average CPU across the fleet. Works alongside the request-count policy:
# scale-out happens if EITHER policy needs more capacity; scale-in only happens when
# BOTH policies agree the fleet is over-provisioned.
resource "aws_autoscaling_policy" "target_tracking_cpu" {
  name                      = "${var.naming_prefix}-target-tracking-cpu"
  autoscaling_group_name    = aws_autoscaling_group.web_fleet.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 120

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70
  }
}

resource "aws_autoscaling_policy" "predictive_scaling" {
  name                   = "${var.naming_prefix}-predictive-scaling"
  autoscaling_group_name = aws_autoscaling_group.web_fleet.name
  policy_type            = "PredictiveScaling"

  predictive_scaling_configuration {
    metric_specification {
      target_value = 1000 # Adjust as you need
      predefined_metric_pair_specification {
        predefined_metric_type = "ALBRequestCount"
        resource_label         = var.alb_target_group_resource_label
      }
    }
    mode                   = "ForecastOnly" # start here, check forecasts, then switch to ForecastAndScale
    scheduling_buffer_time = 300
  }
}
