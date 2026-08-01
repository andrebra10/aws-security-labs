output "ec2_sg_id" {
  description = "Security group ID attached to the EC2 instance."
  value       = aws_security_group.ec2.id
}

output "rds_sg_id" {
  description = "Security group ID attached to the RDS instance."
  value       = aws_security_group.rds.id
}
