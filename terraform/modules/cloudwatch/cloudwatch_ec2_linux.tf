############################################
# CLOUDWATCH LOG GROUP
############################################

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/${var.naming_prefix}/ec2/linux"
  retention_in_days = 7 # Adjust as you need
  kms_key_id        = var.ec2_linux_kms_key_arn

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-ec2-linux-logs"
  })
}
