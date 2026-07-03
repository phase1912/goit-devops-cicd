output "bucket_url" {
  value = aws_s3_bucket.state.bucket_regional_domain_name
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.locks.name
}
