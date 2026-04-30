# IAM task role for Fargate
resource "aws_iam_role" "app" {
  name = "${var.app_name}-${var.environment}-app"

  assume_role_policy = data.aws_iam_policy_document.app_assume_role.json
}

data "aws_iam_policy_document" "app_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# S3 permissions: generate presigned URLs (PutObject) and read objects
resource "aws_iam_policy" "app_s3" {
  name   = "${var.app_name}-${var.environment}-s3"
  policy = data.aws_iam_policy_document.app_s3.json
}

data "aws_iam_policy_document" "app_s3" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${var.s3_bucket_arn}/*"]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [var.s3_bucket_arn]
  }
}

resource "aws_iam_role_policy_attachment" "app_s3" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.app_s3.arn
}

# SSM read permission for the app to fetch SESSION_SECRET at startup
resource "aws_iam_policy" "app_ssm" {
  name   = "${var.app_name}-${var.environment}-ssm"
  policy = data.aws_iam_policy_document.app_ssm.json
}

data "aws_iam_policy_document" "app_ssm" {
  statement {
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:aws:ssm:${var.aws_region}:*:parameter/${var.app_name}/${var.environment}/*"]
  }

  statement {
    actions   = ["kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "app_ssm" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.app_ssm.arn
}

resource "aws_iam_role_policy_attachment" "execution_ssm" {
  role       = aws_iam_role.execution.name
  policy_arn = aws_iam_policy.app_ssm.arn
}
