resource "aws_s3_bucket" "mapshots" {
  bucket = "pasta-atlas-local-mapshots"
}

resource "aws_s3_bucket_ownership_controls" "mapshots" {
  bucket = aws_s3_bucket.mapshots.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "mapshots" {
  bucket = aws_s3_bucket.mapshots.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "mapshots" {
  bucket = aws_s3_bucket.mapshots.id

  rule {
    id     = "expire-guest"
    status = "Enabled"

    filter {
      prefix = "guest/maps/"
    }

    expiration {
      days = 8
    }
  }
}

resource "aws_s3_object" "guest_avatar" {
  bucket       = aws_s3_bucket.mapshots.id
  key          = "guest/avatar/guest.png"
  source       = "../../../frontend/factorio-icons/entity/character.png"
  content_type = "image/png"
  source_hash  = filemd5("../../../frontend/factorio-icons/entity/character.png")
}

resource "aws_s3_object" "compilatron_avatar" {
  bucket       = aws_s3_bucket.mapshots.id
  key          = "compilatron/avatar/compilatron.png"
  source       = "../../../app/assets/images/compilatron.png"
  content_type = "image/png"
  source_hash  = filemd5("../../../app/assets/images/compilatron.png")
}

resource "aws_s3_bucket_cors_configuration" "mapshots" {
  bucket = aws_s3_bucket.mapshots.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST", "PUT"]
    allowed_origins = var.allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}
