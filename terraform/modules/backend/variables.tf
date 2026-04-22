variable "project"            { type = string }
variable "vpc_id"             { type = string }
variable "public_subnet_ids"  { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "sg_alb_id"          { type = string }
variable "sg_ecs_id"          { type = string }
variable "redis_url"          { type = string }
variable "acm_arn"            { type = string }
