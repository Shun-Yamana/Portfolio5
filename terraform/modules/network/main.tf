# TODO: VPC, Subnet, IGW, NAT Gateway, Security Group
variable "project" {}
variable "vpc_cidr" {}

output "vpc_id"              { value = "" }
output "public_subnet_ids"   { value = [] }
output "private_subnet_ids"  { value = [] }
output "sg_alb_id"           { value = "" }
output "sg_ecs_id"           { value = "" }
output "sg_redis_id"         { value = "" }
