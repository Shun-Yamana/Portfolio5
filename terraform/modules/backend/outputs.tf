output "alb_dns"         { value = aws_lb.main.dns_name }
output "ecr_repo_url"    { value = aws_ecr_repository.main.repository_url }
