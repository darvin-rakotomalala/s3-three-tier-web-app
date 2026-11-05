############################################
# AWS SYSTEMS MANAGER PARAMETER OUTPUTS
############################################

output "ssm_parameter_name" {
  description = "Name of the SSM parameter holding the CloudWatch Linux agent config"
  value       = aws_ssm_parameter.cloudwatch_linux_config.name
}

output "ssm_parameter_arn" {
  description = "ARN of the SSM parameter holding the CloudWatch Linux agent config"
  value       = aws_ssm_parameter.cloudwatch_linux_config.arn
}

output "ssm_parameter_version" {
  description = "Version of the SSM parameter (increments each time the config changes)"
  value       = aws_ssm_parameter.cloudwatch_linux_config.version
}

output "ssm_parameter_type" {
  description = "Type of the SSM parameter (SecureString)"
  value       = aws_ssm_parameter.cloudwatch_linux_config.type
}
