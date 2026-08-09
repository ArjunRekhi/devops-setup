# General-purpose bucket: application artefacts, exports, ALB access logs.
#
# Everything below the bucket resource is a default AWS does not give you.
# Public access blocking, encryption, versioning and TLS-only access all have to
# be asked for, and the failure mode of forgetting is a public bucket.

locals {
  bucket_name = "${var.namespace}-${var.environment}-${var.bucket_purpose}-${var.region}"

  tags = merge(var.tags, {
    Namespace      = var.namespace
    Environment    = var.environment
    Stage          = var.stage
    DataClass      = var.data_classification
  })
}

resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name

  # Terraform will not empty a bucket to delete it unless told to.
  force_destroy = !var.deletion_protection

  tags = local.tags
}

# Four separate settings, all of which must be on. This is the single most
# important resource in the stack.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  # Disables ACLs entirely, so access is decided by bucket policy alone. ACLs
  # are the mechanism behind most accidental public objects.
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  # Versioning is what makes an accidental overwrite or a ransomware event
  # recoverable. It is also a prerequisite for replication.
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn == null ? "AES256" : "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }

    # Without this, every object read is a separate KMS API call, which becomes
    # both a bill and a throttling limit at volume.
    bucket_key_enabled = var.kms_key_arn != null
  }
}

# Old versions are invisible in the console and billed at full rate forever.
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  depends_on = [aws_s3_bucket_versioning.this]

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  dynamic "rule" {
    for_each = var.transition_to_ia_days == null ? [] : [1]

    content {
      id     = "transition-to-infrequent-access"
      status = "Enabled"

      filter {}

      transition {
        days          = var.transition_to_ia_days
        storage_class = "STANDARD_IA"
      }
    }
  }
}

# Plaintext HTTP is still accepted by S3 unless a policy refuses it.
resource "aws_s3_bucket_policy" "tls_only" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.this.arn,
        "${aws_s3_bucket.this.arn}/*",
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}
