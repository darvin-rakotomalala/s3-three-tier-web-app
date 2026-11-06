############################################
# Application Load Balancer (public-facing to CloudFront only, 3 AZs)
#
# CHANGE: the ALB is no longer the public entry point — CloudFront
# (14-cloudfront.tf) is. The ALB's Security Group only accepts traffic from
# CloudFront's IP ranges (04-security-groups.tf), and as a second,
# independent layer of defense, every request must also carry a secret
# custom header that only CloudFront is configured to send. Without both,
# the ALB returns a flat 403 — this defends against someone finding the
# ALB's DNS name and hitting it directly from within CloudFront's own IP
# ranges (e.g. another AWS customer's CloudFront distribution).
############################################

# Secret shared between the ALB listener rule and CloudFront's origin
# custom header (14-cloudfront.tf). Rotate by tainting this resource.
resource "random_password" "cloudfront_origin_secret" {
  length  = 32
  special = false
}

resource "aws_lb" "app" {
  name               = "${var.naming_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2               = true
  drop_invalid_header_fields = true

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alb"
  })
}

# ---------- Target Group: forwards to the app-tier Auto Scaling Group ----------
resource "aws_lb_target_group" "app" {
  name        = "${var.naming_prefix}-app-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200-399"
  }

  # Required for target-tracking scaling on ALBRequestCountPerTarget
  # (see 15-launch-template-asg.tf) to behave predictably during scale-in.
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-app-tg"
  })
}

# ---------- Listener 80 (HTTP) -> redirect to HTTPS ----------
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ---------- Listener 443 (HTTPS) ----------
# Default action denies everything; only requests carrying the correct
# secret header (i.e. genuinely from CloudFront) are forwarded, via the
# listener rule below.
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06" # supports TLS 1.2 and TLS 1.3
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "403"
      message_body = "Forbidden"
    }
  }
}

resource "aws_lb_listener_rule" "require_cloudfront_header" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    http_header {
      http_header_name = "X-Origin-Verify"
      values           = [random_password.cloudfront_origin_secret.result]
    }
  }
}
