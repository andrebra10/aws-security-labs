variable "project_name" {
  description = "Prefix used to name RDS resources."
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the two private subnets the DB subnet group spans."
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Security group ID allowed to reach RDS (the EC2 security group)."
  type        = string
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "ppk"
}

variable "db_username" {
  description = "Master username for the RDS instance."
  type        = string
  default     = "ppkapp"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB."
  type        = number
  default     = 20
}
