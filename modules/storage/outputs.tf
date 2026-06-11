output "rds_endpoint" {
  value     = aws_db_instance.postgres.endpoint
  sensitive = true
}

output "s3_bucket_name" {
  value = aws_s3_bucket.main.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.pedidos.name
}
