# TODO: ECR, ECS Cluster/TaskDef/Service, ALB, CloudWatch Logs, IAM Role
variable "project"            {}
variable "vpc_id"             {}
variable "public_subnet_ids"  {}
variable "private_subnet_ids" {}
variable "sg_alb_id"          {}
variable "sg_ecs_id"          {}
variable "redis_url"          {}
variable "acm_arn"            {}

output "alb_dns" { value = "" }
