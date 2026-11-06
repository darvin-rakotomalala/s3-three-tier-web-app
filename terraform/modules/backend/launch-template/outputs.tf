############################################
# LAUNCH TEMPLATE OUTPUTS
############################################

output "app_launch_template_id" {
  description = "ID of the launch template used by the web fleet"
  value       = aws_launch_template.web_fleet.id
}

data "aws_instances" "app" {
  filter {
    name   = "tag:Name"
    values = ["${var.naming_prefix}-web-fleet"]
  }

  instance_state_names = ["running"]

  # If the ASG lives in this module, uncomment so the lookup runs after it exists:
  depends_on = [var.app_autoscaling_group_name]
}

output "app_instance_ids" {
  description = "IDs of the running web fleet instances"
  value       = data.aws_instances.app.ids
}

output "launch_template_latest_version" {
  description = "Latest version number of the web fleet launch template"
  value       = aws_launch_template.web_fleet.latest_version
}
