output "cf_domain"      { value = aws_cloudfront_distribution.main.domain_name }
output "s3_bucket_name" { value = aws_s3_bucket.frontend.bucket }
