output "bucket_name" {
  description = "Name of the company data bucket."
  value       = aws_s3_bucket.data.id
}

output "bucket_arn" {
  description = "ARN of the company data bucket."
  value       = aws_s3_bucket.data.arn
}
