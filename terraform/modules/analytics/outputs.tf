output "firehose_name"    { value = aws_kinesis_firehose_delivery_stream.main.name }
output "logs_bucket"      { value = aws_s3_bucket.logs.bucket }
output "athena_workgroup" { value = aws_athena_workgroup.main.name }
