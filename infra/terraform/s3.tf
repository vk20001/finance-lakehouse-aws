locals {
  common_tags = {
    Project = var.project_prefix
    Owner   = var.owner
    Env     = "dev"
  }
}

# Buckets
resource "aws_s3_bucket" "raw" {
  bucket = "${var.project_prefix}-raw-${var.bucket_suffix}"
  tags   = local.common_tags
}

resource "aws_s3_bucket" "clean" {
  bucket = "${var.project_prefix}-clean-${var.bucket_suffix}"
  tags   = local.common_tags
}

resource "aws_s3_bucket" "gold" {
  bucket = "${var.project_prefix}-gold-${var.bucket_suffix}"
  tags   = local.common_tags
}

# Block public access
resource "aws_s3_bucket_public_access_block" "raw_pab" {
  bucket                  = aws_s3_bucket.raw.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_public_access_block" "clean_pab" {
  bucket                  = aws_s3_bucket.clean.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_public_access_block" "gold_pab" {
  bucket                  = aws_s3_bucket.gold.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle on RAW: expire after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "raw_lifecycle" {
  bucket = aws_s3_bucket.raw.id
  rule {
    id     = "expire-raw-30d"
    status = "Enabled"
    expiration { days = 30 }
    filter { prefix = "" }
  }
}
