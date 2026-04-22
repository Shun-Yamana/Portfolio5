terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "tfstate-portfolio5-203553641035"
    key            = "portfolio5/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

# ACM(CloudFront用) は us-east-1 固定
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "network" {
  source = "./modules/network"

  project          = var.project
  region           = var.region
  vpc_cidr         = var.vpc_cidr
  use_nat_gateway  = var.use_nat_gateway
  use_vpc_endpoints = var.use_vpc_endpoints
}

module "dns" {
  source = "./modules/dns"

  project     = var.project
  domain      = var.domain
  alb_dns     = module.backend.alb_dns
  cf_domain   = module.frontend.cf_domain

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}

module "redis" {
  source = "./modules/redis"

  project            = var.project
  subnet_ids         = module.network.private_subnet_ids
  security_group_id  = module.network.sg_redis_id
}

module "backend" {
  source = "./modules/backend"

  project            = var.project
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  sg_alb_id          = module.network.sg_alb_id
  sg_ecs_id          = module.network.sg_ecs_id
  redis_url          = "redis://${module.redis.redis_endpoint}:6379/0"
  acm_arn            = module.dns.acm_arn_alb
  bedrock_policy_arn = module.analytics.bedrock_policy_arn
}

module "frontend" {
  source = "./modules/frontend"

  project     = var.project
  acm_arn     = module.dns.acm_arn_cf
  api_base_url = "https://api.${var.domain}"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}

module "analytics" {
  source = "./modules/analytics"

  project = var.project
  region  = var.region
}
