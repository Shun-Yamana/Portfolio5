terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# ── VPC ──────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project}-vpc" }
}

# ── Subnets ───────────────────────────────────────────
resource "aws_subnet" "public" {
  for_each = {
    a = { cidr = "10.0.1.0/24", az = "${var.region}a" }
    c = { cidr = "10.0.2.0/24", az = "${var.region}c" }
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = { Name = "${var.project}-public-${each.key}" }
}

resource "aws_subnet" "private" {
  for_each = {
    a = { cidr = "10.0.11.0/24", az = "${var.region}a" }
    c = { cidr = "10.0.12.0/24", az = "${var.region}c" }
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = { Name = "${var.project}-private-${each.key}" }
}

# ── IGW ───────────────────────────────────────────────
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-igw" }
}

# ── NAT Gateway（本番のみ）────────────────────────────
resource "aws_eip" "nat" {
  count  = var.use_nat_gateway ? 1 : 0
  domain = "vpc"
  tags   = { Name = "${var.project}-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  count         = var.use_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public["a"].id
  tags          = { Name = "${var.project}-nat" }
}

# ── Route Tables ──────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.project}-rt-public" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.use_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = { Name = "${var.project}-rt-private" }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# ── VPC Endpoints（オプション）───────────────────────
resource "aws_vpc_endpoint" "s3" {
  count             = var.use_vpc_endpoints ? 1 : 0
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = { Name = "${var.project}-ep-s3" }
}

resource "aws_vpc_endpoint" "ecr_api" {
  count               = var.use_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
  tags                = { Name = "${var.project}-ep-ecr-api" }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = var.use_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
  tags                = { Name = "${var.project}-ep-ecr-dkr" }
}

resource "aws_vpc_endpoint" "logs" {
  count               = var.use_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
  tags                = { Name = "${var.project}-ep-logs" }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  count               = var.use_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
  tags                = { Name = "${var.project}-ep-secretsmanager" }
}

# ── Security Groups ───────────────────────────────────
resource "aws_security_group" "alb" {
  name   = "${var.project}-sg-alb"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-sg-alb" }
}

resource "aws_security_group" "ecs" {
  name   = "${var.project}-sg-ecs"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-sg-ecs" }
}

resource "aws_security_group" "redis" {
  name   = "${var.project}-sg-redis"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = { Name = "${var.project}-sg-redis" }
}

resource "aws_security_group" "vpc_endpoint" {
  name   = "${var.project}-sg-vpc-endpoint"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = { Name = "${var.project}-sg-vpc-endpoint" }
}
