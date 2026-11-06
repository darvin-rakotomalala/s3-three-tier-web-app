############################################
# ALB OUTPUTS
############################################

output "alb_dns_name" {
  description = "ALB's own DNS name — internal use only, not reachable from outside CloudFront's IP ranges"
  value       = aws_lb.app.dns_name
}

output "alb_zone_id" {
  description = "Route 53 hosted zone ID of the application load balancer, used for creating alias records"
  value       = aws_lb.app.zone_id
}

output "alb_target_group_arn" {
  description = "ARN of the application load balancer target group"
  value       = aws_lb_target_group.app.arn
}

output "alb_arn_suffix" {
  description = "The ARN suffix for use with CloudWatch Metrics."
  value       = aws_lb.app.arn_suffix
}

output "target_group_arn_suffix" {
  description = "The ARN suffix for use with CloudWatch Metrics."
  value       = aws_lb_target_group.app.arn_suffix
}

output "lb_listener_https" {
  description = "HTTPS of ALB listener"
  value       = aws_lb_listener.https.arn
}

output "lb_target_group_app_arn" {
  description = "ARN of the application target group"
  value       = aws_lb_target_group.app.arn
}

output "cloudfront_origin_secret_result" {
  description = "Shared secret value CloudFront sends to the origin (e.g. as a custom header) so the ALB can verify requests came through CloudFront"
  value       = random_password.cloudfront_origin_secret.result
  sensitive   = true
}

output "alb_target_group_resource_label" {
  description = "Resource label (ALB and target group ARN suffixes) for the ALBRequestCountPerTarget target-tracking scaling metric"
  value       = "${aws_lb.app.arn_suffix}/${aws_lb_target_group.app.arn_suffix}"
}
