# TODO: ElastiCache Subnet Group, Redis Cluster
variable "project"           {}
variable "subnet_ids"        {}
variable "security_group_id" {}

output "redis_endpoint" { value = "" }
