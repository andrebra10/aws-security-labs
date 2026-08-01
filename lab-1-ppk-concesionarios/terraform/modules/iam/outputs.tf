output "instance_profile_name" {
  description = "Name of the instance profile to attach to the EC2 instance."
  value       = aws_iam_instance_profile.ec2.name
}

output "role_arn" {
  description = "ARN of the IAM role assumed by the EC2 instance."
  value       = aws_iam_role.ec2.arn
}
