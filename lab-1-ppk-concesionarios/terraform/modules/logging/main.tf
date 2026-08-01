# CloudTrail + GuardDuty: the "blue team" half of this lab. Nothing here is
# part of the attack chain - it exists so the same scenario can be replayed
# and reviewed from the defender's side (what got logged, what GuardDuty
# flagged) after the pentest.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --- CloudTrail: management events, delivered to a dedicated, private S3
# bucket and mirrored to CloudWatch Logs for near-real-time review ---

resource "random_id" "trail_bucket_suffix" {
  byte_length = 3
}

resource "aws_s3_bucket" "trail" {
  bucket = "${var.project_name}-cloudtrail-${random_id.trail_bucket_suffix.hex}"

  tags = {
    Name = "${var.project_name}-cloudtrail-${random_id.trail_bucket_suffix.hex}"
  }
}

resource "aws_s3_bucket_public_access_block" "trail" {
  bucket = aws_s3_bucket.trail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail" {
  bucket = aws_s3_bucket.trail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

locals {
  trail_name = "${var.project_name}-trail"
  trail_arn  = "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${local.trail_name}"
}

data "aws_iam_policy_document" "trail_bucket" {
  statement {
    sid       = "AWSCloudTrailAclCheck"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.trail.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid       = "AWSCloudTrailWrite"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.trail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "trail" {
  bucket = aws_s3_bucket.trail.id
  policy = data.aws_iam_policy_document.trail_bucket.json
}

resource "aws_cloudwatch_log_group" "trail" {
  name              = "/ppk/${local.trail_name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "trail_cloudwatch_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "trail_cloudwatch" {
  name               = "${var.project_name}-cloudtrail-cwl-role"
  assume_role_policy = data.aws_iam_policy_document.trail_cloudwatch_trust.json
}

data "aws_iam_policy_document" "trail_cloudwatch_permissions" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.trail.arn}:*"]
  }
}

resource "aws_iam_role_policy" "trail_cloudwatch" {
  name   = "${var.project_name}-cloudtrail-cwl-policy"
  role   = aws_iam_role.trail_cloudwatch.id
  policy = data.aws_iam_policy_document.trail_cloudwatch_permissions.json
}

resource "aws_cloudtrail" "this" {
  name                          = local.trail_name
  s3_bucket_name                = aws_s3_bucket.trail.id
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_logging                = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.trail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.trail_cloudwatch.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [aws_s3_bucket_policy.trail]

  tags = {
    Name = local.trail_name
  }
}

# --- GuardDuty: account-level threat detection. In this lab it's the piece
# most likely to actually flag the attack chain, via
# UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration if the stolen
# instance-role credentials are used from outside AWS (see docs/detection.md) ---

resource "aws_guardduty_detector" "this" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true

  finding_publishing_frequency = "FIFTEEN_MINUTES"
}
