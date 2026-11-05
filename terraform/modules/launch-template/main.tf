############################################
# LAUNCH TEMPLATE
############################################

# Latest Ubuntu 24.04 LTS (Noble Numbat) AMI, owned by Canonical
data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

/*
data "aws_ssm_parameter" "linux_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_ami" "linux" {
  filter {
    name   = "image-id"
    values = [data.aws_ssm_parameter.linux_ami.value]
  }
  owners = ["amazon"]
}
*/

resource "aws_launch_template" "web_fleet" {
  name_prefix   = "${var.environment}-web-fleet-"
  image_id      = data.aws_ami.ubuntu_ami.id # data.aws_ssm_parameter.linux_ami.value
  instance_type = var.instance_type

  iam_instance_profile {
    arn = var.instance_profile_arn
  }

  # vpc_security_group_ids = [var.instance_security_group_id]
  network_interfaces {
    security_groups = [var.app_security_group_id]
  }

  metadata_options {
    http_tokens                 = "required" # Enforce IMDSv2
    http_put_response_hop_limit = 1
    http_endpoint               = "enabled"
    instance_metadata_tags      = "enabled"
  }

  block_device_mappings {
    device_name = data.aws_ami.ubuntu_ami.root_device_name # data.aws_ami.linux.root_device_name
    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.ebs_kms_key_arn
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true # Detailed CloudWatch monitoring (1-minute granularity)
  }

  user_data = filebase64("${path.module}/user_data.sh")

  /*
  user_data = base64encode(templatefile("${path.module}/../user_data/user_data.tpl", {
    Parameter_Name = var.ssm_parameter_name
  }))
  */

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name = "${var.naming_prefix}-web-fleet"
    })
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    var.jar_artifacts_bucket_name,
    var.ec2_linux_kms_key_policy_id,
    var.ec2_linux_kms_alias_arn,
  ]
}
