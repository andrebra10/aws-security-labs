variable "project_name" {
  description = "Prefix used to name the IAM role, policy and instance profile."
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the S3 bucket the EC2 instance is allowed to read (list + get only)."
  type        = string
}
