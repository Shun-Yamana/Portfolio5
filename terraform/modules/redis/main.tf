terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project}-redis-subnet-group"
  subnet_ids = var.subnet_ids

  tags = { Name = "${var.project}-redis-subnet-group" }
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project}-redis"
  description          = "Valkey Pub/Sub for ${var.project}"

  engine               = "valkey"
  node_type            = "cache.t4g.micro"
  num_cache_clusters   = 1
  port                 = 6379

  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [var.security_group_id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  tags = { Name = "${var.project}-redis" }
}
