############################################
# Route 53
# Uses the existing hosted zone (var.route53_zone_id) for var.domain_name.
#
#   cloudwithdarvin.com      -> CloudFront distribution  (public)
#   api.cloudwithdarvin.com  -> CloudFront distribution  (public)
#   origin.cloudwithdarvin.com -> ALB                    (internal plumbing only,
#                                                          used solely as
#                                                          CloudFront's origin)
############################################

data "aws_route53_zone" "main" {
  zone_id = var.route53_zone_id
}

# ---------- Public-facing records: alias to CloudFront ----------
resource "aws_route53_record" "api_alias" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.api_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# ---------- Internal record: alias to the ALB ----------
# Not advertised anywhere publicly — exists solely so CloudFront has a
# stable hostname (with a matching ACM certificate) to use as its origin.
resource "aws_route53_record" "origin_alias" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.origin_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
