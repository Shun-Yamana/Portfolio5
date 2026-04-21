output "app_url" {
  description = "フロントエンドURL"
  value       = "https://app.${var.domain}"
}

output "api_url" {
  description = "バックエンドURL"
  value       = "https://api.${var.domain}"
}

output "cloudfront_domain" {
  description = "CloudFrontドメイン"
  value       = module.frontend.cf_domain
}

output "alb_dns" {
  description = "ALB DNS名"
  value       = module.backend.alb_dns
}
