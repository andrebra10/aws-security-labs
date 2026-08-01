resource "random_id" "bucket_suffix" {
  byte_length = 3
}

resource "aws_s3_bucket" "data" {
  bucket = "${var.bucket_name_prefix}-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.bucket_name_prefix}-${random_id.bucket_suffix.hex}"
  }
}

# The bucket itself is fully private - this lab's vector is a compromised
# IAM role, not a misconfigured public bucket.
resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Business documents actually used by the application (brochures/) ---

resource "aws_s3_object" "brochures" {
  for_each = fileset("${path.module}/files/brochures", "**")

  bucket = aws_s3_bucket.data.id
  key    = "brochures/${each.value}"
  source = "${path.module}/files/brochures/${each.value}"
  etag   = filemd5("${path.module}/files/brochures/${each.value}")
}

# --- Sensitive company data that has nothing to do with the app feature ---
# (this is what an attacker who inherits the instance role actually goes after)

resource "aws_s3_object" "contracts" {
  for_each = fileset("${path.module}/files/contracts", "**")

  bucket = aws_s3_bucket.data.id
  key    = "contracts/${each.value}"
  source = "${path.module}/files/contracts/${each.value}"
  etag   = filemd5("${path.module}/files/contracts/${each.value}")
}

resource "aws_s3_object" "exports" {
  for_each = fileset("${path.module}/files/exports", "**")

  bucket = aws_s3_bucket.data.id
  key    = "exports/${each.value}"
  source = "${path.module}/files/exports/${each.value}"
  etag   = filemd5("${path.module}/files/exports/${each.value}")
}

resource "aws_s3_object" "finance" {
  for_each = fileset("${path.module}/files/finance", "**")

  bucket = aws_s3_bucket.data.id
  key    = "finance/${each.value}"
  source = "${path.module}/files/finance/${each.value}"
  etag   = filemd5("${path.module}/files/finance/${each.value}")
}

resource "aws_s3_object" "old_config" {
  for_each = fileset("${path.module}/files/old-config", "**")

  bucket = aws_s3_bucket.data.id
  key    = "old-config/${each.value}"
  source = "${path.module}/files/old-config/${each.value}"
  etag   = filemd5("${path.module}/files/old-config/${each.value}")
}
