############################################
# ASG OUTPUTS
############################################

output "app_autoscaling_group_name" {
  description = "Name of the Auto Scaling Group managing the web fleet"
  value       = aws_autoscaling_group.web_fleet.name
}

# The ASG doesn't expose instance IDs, so look up the instances
# it launched via the auto-applied aws:autoscaling:groupName tag.
data "aws_instances" "web_fleet" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.web_fleet.name]
  }

  # Excludes stopped warm-pool instances and terminated ones
  instance_state_names = ["pending", "running"]

  depends_on = [aws_autoscaling_group.web_fleet]
}

output "ec2_instance_ids" {
  description = "IDs of the running EC2 instances in the web fleet ASG"
  value       = data.aws_instances.web_fleet.ids
}

output "ec2_instance_private_ips" {
  description = "Private IPs of the web fleet instances (optional, handy for debugging)"
  value       = data.aws_instances.web_fleet.private_ips
}
