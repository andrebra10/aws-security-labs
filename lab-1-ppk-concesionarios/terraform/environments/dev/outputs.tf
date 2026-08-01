output "ec2_public_ip" {
  description = "Public IP of the EC2 instance. Add it to your /etc/hosts (or C:\\Windows\\System32\\drivers\\etc\\hosts) file for both ppkconcesionario.com and dev.ppkconcesionario.com."
  value       = module.ec2.public_ip
}

output "hosts_file_entries" {
  description = "Lines to append to your hosts file."
  value       = <<-EOT
    ${module.ec2.public_ip} ppkconcesionario.com
    ${module.ec2.public_ip} dev.ppkconcesionario.com
  EOT
}

output "admin_ssh_command" {
  description = "SSH command to administer the box (unrelated to the vulnerability chain)."
  value       = "ssh -i ${module.ec2.admin_private_key_path} ubuntu@${module.ec2.public_ip}"
}

output "rds_endpoint" {
  description = "RDS endpoint (private, only reachable from the EC2 instance)."
  value       = "${module.rds.db_host}:${module.rds.db_port}"
}

output "s3_bucket_name" {
  description = "Name of the company data bucket."
  value       = module.s3.bucket_name
}

output "cloudtrail_log_group_name" {
  description = "CloudWatch Logs group with near-real-time CloudTrail events. Search it in the AWS console under CloudWatch > Log groups."
  value       = module.logging.cloudtrail_log_group_name
}

output "cloudtrail_bucket_name" {
  description = "S3 bucket holding the full CloudTrail history."
  value       = module.logging.cloudtrail_bucket_name
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID. View findings in the AWS console under GuardDuty > Findings."
  value       = module.logging.guardduty_detector_id
}
