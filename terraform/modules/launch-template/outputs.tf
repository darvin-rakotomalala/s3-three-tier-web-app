############################################
# LAUNCH TEMPLATE OUTPUTS
############################################

output "app_launch_template_id" {
  description = "ID of the launch template used by the web fleet"
  value       = aws_launch_template.web_fleet.id
}

output "launch_template_latest_version" {
  description = "Latest version number of the web fleet launch template"
  value       = aws_launch_template.web_fleet.latest_version
}
