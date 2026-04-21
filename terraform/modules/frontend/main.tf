# TODO: S3 Bucket, CloudFront Distribution, OAC
variable "project"      {}
variable "acm_arn"      {}
variable "api_base_url" {}

output "cf_domain" { value = "" }
