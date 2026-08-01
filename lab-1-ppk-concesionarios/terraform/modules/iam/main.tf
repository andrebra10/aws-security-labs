# The application legitimately needs to read a handful of marketing brochures
# out of the shared company bucket for the "Documentación comercial" feature.
# The role below grants exactly that: ListBucket + GetObject, nothing else,
# and no admin-style permissions of any kind.
#
# The catch (intentional, and typical of real deployments): the permission is
# scoped to the *bucket*, not to the "brochures/" prefix the app actually
# uses. The same bucket also stores contracts, customer exports and financial
# reports that have nothing to do with this feature - so anything that gets
# hold of this role's credentials can read all of it, not just the brochures.

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

data "aws_iam_policy_document" "s3_read_only" {
  statement {
    sid       = "ListCompanyBucket"
    actions   = ["s3:ListBucket"]
    resources = [var.bucket_arn]
  }

  statement {
    sid       = "ReadCompanyBucketObjects"
    actions   = ["s3:GetObject"]
    resources = ["${var.bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "s3_read_only" {
  name   = "${var.project_name}-s3-read-only"
  role   = aws_iam_role.ec2.id
  policy = data.aws_iam_policy_document.s3_read_only.json
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2.name
}
