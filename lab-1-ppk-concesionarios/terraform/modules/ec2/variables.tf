variable "project_name" {
  description = "Prefix used to name EC2-related resources."
  type        = string
}

variable "subnet_id" {
  description = "Public subnet where the instance is launched."
  type        = string
}

variable "security_group_id" {
  description = "Security group attached to the instance."
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile granting S3 read access."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.small"
}

variable "github_repo_url" {
  description = "Public GitHub repository the instance clones the application source from."
  type        = string
}

variable "dev_password" {
  description = "Password shared by the dev-mode application account (DEV_USERNAME/DEV_PASSWORD in .env) and the 'pepe' Linux account."
  type        = string
  sensitive   = true
}

variable "app_secret_key" {
  description = "Random secret key used to sign the FastAPI session cookie."
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region, passed through to the application for the boto3 client."
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket the application reads brochures from."
  type        = string
}

variable "db_host" {
  description = "RDS endpoint hostname."
  type        = string
}

variable "db_port" {
  description = "RDS port."
  type        = number
}

variable "db_name" {
  description = "Database name."
  type        = string
}

variable "db_username" {
  description = "Database username."
  type        = string
}

variable "db_password" {
  description = "Database password."
  type        = string
  sensitive   = true
}
