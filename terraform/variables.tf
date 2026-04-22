variable "project" {
  description = "プロジェクト名（リソース名のプレフィックスに使用）"
  type        = string
  default     = "portfolio5"
}

variable "region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "vpc_cidr" {
  description = "VPC CIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain" {
  description = "Route53で管理するドメイン名"
  type        = string
}

variable "use_nat_gateway" {
  description = "trueでNAT Gateway、falseでVPC Endpoint（開発用）"
  type        = bool
  default     = false
}

variable "use_vpc_endpoints" {
  description = "trueでVPC Endpointを作成（ECS→ECR/Logs/Secretsmanager）"
  type        = bool
  default     = false
}
