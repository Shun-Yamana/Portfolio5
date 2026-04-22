output "acm_arn_alb"    { value = aws_acm_certificate_validation.alb.certificate_arn }
output "acm_arn_cf"     { value = aws_acm_certificate_validation.cf.certificate_arn }
output "hosted_zone_id" { value = aws_route53_zone.main.zone_id }
output "name_servers"   { value = aws_route53_zone.main.name_servers }
