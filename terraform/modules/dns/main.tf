# TODO: Route53 Hosted Zone, ACM(東京/us-east-1), Aレコード
variable "project"   {}
variable "domain"    {}
variable "alb_dns"   {}
variable "cf_domain" {}

output "acm_arn_alb" { value = "" }
output "acm_arn_cf"  { value = "" }
