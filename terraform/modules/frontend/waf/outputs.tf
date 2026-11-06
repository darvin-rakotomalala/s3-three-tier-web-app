####################################################
# WAF OUTPUTS
####################################################

output "cf_waf_acl_arn" {
  description = "ARN of the CloudFront WAF ACL"
  value       = aws_wafv2_web_acl.main.arn
}
