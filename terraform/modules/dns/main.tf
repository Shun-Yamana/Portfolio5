terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

# ── Route53 Hosted Zone ───────────────────────────────
resource "aws_route53_zone" "main" {
  name = var.domain
  tags = { Name = var.domain }
}

# ── ACM（ALB用 / 東京）───────────────────────────────
resource "aws_acm_certificate" "alb" {
  domain_name               = "api.${var.domain}"
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${var.project}-acm-alb" }
}

resource "aws_route53_record" "alb_validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for r in aws_route53_record.alb_validation : r.fqdn]
}

# ── ACM（CloudFront用 / us-east-1）───────────────────
resource "aws_acm_certificate" "cf" {
  provider                  = aws.us_east_1
  domain_name               = "app.${var.domain}"
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${var.project}-acm-cf" }
}

resource "aws_route53_record" "cf_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cf.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cf" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cf.arn
  validation_record_fqdns = [for r in aws_route53_record.cf_validation : r.fqdn]
}

# ── Route53 Aレコード（api.<domain> → ALB）───────────
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.${var.domain}"
  type    = "A"

  alias {
    name                   = var.alb_dns
    zone_id                = "Z14GRHDCWA56QT"  # ALBのHosted Zone ID（東京固定）
    evaluate_target_health = true
  }
}

# ── Route53 Aレコード（app.<domain> → CloudFront）────
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.${var.domain}"
  type    = "A"

  alias {
    name                   = var.cf_domain
    zone_id                = "Z2FDTNDATAQYW2"  # CloudFrontのHosted Zone ID（全リージョン固定）
    evaluate_target_health = false
  }
}
