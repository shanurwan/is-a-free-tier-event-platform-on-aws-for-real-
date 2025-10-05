variable "name" {
  type = string
}

variable "lifecycle_days_to_ia" {
  type    = number
  default = 30
}

resource "aws_s3_bucket" "this" {
  bucket = var.name
}

resource "aws_s3_bucket_public_access_block" "b" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "v" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lc" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "to-ia"
    status = "Enabled"

    transition {
      days          = var.lifecycle_days_to_ia
      storage_class = "STANDARD_IA"
    }
  }
}

output "name" {
  value = aws_s3_bucket.this.bucket
}

