variable "project_name" {
  description = "Prefix used to name and tag the security groups."
  type        = string
}

variable "vpc_id" {
  description = "VPC where the security groups are created."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to reach the EC2 instance on port 22 (the pentester's/admin's IP, e.g. 203.0.113.10/32)."
  type        = string
}
