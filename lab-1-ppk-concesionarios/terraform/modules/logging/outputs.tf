output "cloudtrail_bucket_name" {
  description = "S3 bucket receiving CloudTrail logs."
  value       = aws_s3_bucket.trail.id
}

output "cloudtrail_log_group_name" {
  description = "CloudWatch Logs group mirroring CloudTrail events (near-real-time)."
  value       = aws_cloudwatch_log_group.trail.name
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID (empty if disabled)."
  value       = try(aws_guardduty_detector.this[0].id, "")
}
