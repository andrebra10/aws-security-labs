variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Prefix applied to every resource name/tag."
  type        = string
  default     = "ppk"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the EC2 instance, e.g. \"203.0.113.10/32\". Use your own public IP, never 0.0.0.0/0."
  type        = string
}

variable "github_repo_url" {
  description = "Public GitHub repository the EC2 instance clones the application source from."
  type        = string
  default     = "https://github.com/andrebra10/aws-security-labs.git"
}

variable "dev_password" {
  description = "Password reused by the dev-mode application account and the 'pepe' Linux account. Deliberately weak/hardcoded to mirror a real developer habit - do not change unless you're also updating the lab documentation."
  type        = string
  default     = "Summer2025!"
  sensitive   = true
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the two private subnets."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type for the web/dev server."
  type        = string
  default     = "t3.small"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Application database name."
  type        = string
  default     = "ppk"
}

variable "db_username" {
  description = "RDS master username."
  type        = string
  default     = "ppkapp"
}

variable "bucket_name_prefix" {
  description = "Prefix for the company data S3 bucket (a random suffix is appended)."
  type        = string
  default     = "ppk-company-data"
}
