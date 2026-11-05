############################################
# AWS SYSTEMS MANAGER PARAMETER
############################################

locals {
  config_json = templatefile("${path.module}/../cloudwatch_config/linux_config.json.tftpl", {
    log_group_name = var.ec2_linux_log_group_name
  })
}

resource "aws_ssm_parameter" "cloudwatch_linux_config" {
  name   = "/${var.naming_prefix}/Amazon-CloudWatch-Linux-Config"
  type   = "SecureString"
  key_id = var.ec2_linux_kms_key_id
  value  = local.config_json

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-ssm-parameter"
  })
}
