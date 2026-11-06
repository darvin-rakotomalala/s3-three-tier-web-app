############################################
# ACM Certificates (reconfigured for CloudFront)
#
# Two separate certificates are required once CloudFront sits in front of
# the ALB:
#
# 1. "origin" — a REGIONAL certificate (in var.primary_region, wherever the
#    ALB actually lives), covering only the internal
#    origin.<domain> hostname. This is what the ALB's HTTPS listener
#    presents. CloudFront validates this certificate's hostname against its
#    configured Origin Domain Name when connecting over HTTPS — a cert
#    covering the ALB's own *.elb.amazonaws.com name is not obtainable from
#    ACM, so a dedicated origin subdomain (aliased to the ALB in Route 53,
#    see 12-route53.tf) is required for this to work at all.
#
# 2. "cloudfront" — a certificate in us-east-1 (CloudFront's viewer
#    certificates must always live there, regardless of var.primary_region),
#    covering the public-facing domain_name and api_subdomain. This is what
#    viewers (browsers/clients) see when they hit CloudFront over HTTPS.
#
# Both are DNS-validated against the same existing Route 53 hosted zone.
############################################

# ---------- 1. Origin certificate (ALB, regional) ----------
resource "aws_acm_certificate" "origin" {
  domain_name       = "${var.origin_subdomain}.${var.domain_name}"
  validation_method = "DNS"
  key_algorithm     = "RSA_2048"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-origin-cert"
  })
}

resource "aws_route53_record" "origin_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.origin.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "origin" {
  certificate_arn         = aws_acm_certificate.origin.arn
  validation_record_fqdns = [for r in aws_route53_record.origin_cert_validation : r.fqdn]
}

# ---------- 2. CloudFront viewer certificate (us-east-1, public-facing) ----------
resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = ["${var.api_subdomain}.${var.domain_name}"]
  validation_method         = "DNS"
  key_algorithm             = "RSA_2048"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-cloudfront-cert"
  })
}

resource "aws_route53_record" "cloudfront_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for r in aws_route53_record.cloudfront_cert_validation : r.fqdn]
}
