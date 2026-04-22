terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# ── S3 Bucket（ログ保存）──────────────────────────────
resource "aws_s3_bucket" "logs" {
  bucket        = "${var.project}-chat-logs"
  force_destroy = true

  tags = { Name = "${var.project}-chat-logs" }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# ── S3 Bucket（Athenaクエリ結果）─────────────────────
resource "aws_s3_bucket" "athena_results" {
  bucket        = "${var.project}-athena-results"
  force_destroy = true

  tags = { Name = "${var.project}-athena-results" }
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket                  = aws_s3_bucket.athena_results.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# ── IAM Role（Firehose → S3）─────────────────────────
resource "aws_iam_role" "firehose" {
  name = "${var.project}-firehose"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "firehose.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${var.project}-firehose" }
}

resource "aws_iam_role_policy" "firehose_s3" {
  name = "${var.project}-firehose-s3"
  role = aws_iam_role.firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetBucketLocation",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.logs.arn,
        "${aws_s3_bucket.logs.arn}/*"
      ]
    }]
  })
}

# ── Kinesis Firehose ──────────────────────────────────
resource "aws_kinesis_firehose_delivery_stream" "main" {
  name        = "${var.project}-chat-logs"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose.arn
    bucket_arn         = aws_s3_bucket.logs.arn
    buffering_size     = 5    # MB
    buffering_interval = 300  # 秒

    prefix              = "year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/"
  }

  tags = { Name = "${var.project}-chat-logs" }
}

# ── Glue Database ─────────────────────────────────────
resource "aws_glue_catalog_database" "main" {
  name = "${var.project}_analytics"
}

# ── Glue Table（チャットメッセージスキーマ）──────────
resource "aws_glue_catalog_table" "chat_messages" {
  name          = "chat_messages"
  database_name = aws_glue_catalog_database.main.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification"  = "json"
    "compressionType" = "none"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.logs.bucket}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "message_id"
      type = "string"
    }
    columns {
      name = "content"
      type = "string"
    }
    columns {
      name = "created_at"
      type = "string"
    }
  }

  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
  partition_keys {
    name = "day"
    type = "string"
  }
}

# ── Athena Workgroup ──────────────────────────────────
resource "aws_athena_workgroup" "main" {
  name          = var.project
  force_destroy = true

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/results/"
    }
  }

  tags = { Name = var.project }
}
