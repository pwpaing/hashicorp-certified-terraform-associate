# Create S3 Bucket for Source Maps
resource "aws_s3_bucket" "source_maps" {
  bucket = var.bucket_name

  tags = {
    Name        = "Faro Source Maps Bucket"
    Environment = "Production"
    Purpose     = "Frontend Source Maps Storage"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "source_maps_versioning" {
  bucket = aws_s3_bucket.source_maps.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server-side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "source_maps_encryption" {
  bucket = aws_s3_bucket.source_maps.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "source_maps_public_access" {
  bucket = aws_s3_bucket.source_maps.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
