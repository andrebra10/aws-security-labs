output "public_ip" {
  description = "Public IP address of the EC2 instance."
  value       = aws_instance.this.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.this.id
}

output "admin_private_key_path" {
  description = "Local path to the generated admin SSH private key."
  value       = local_file.admin_private_key.filename
}
