# Role assumed by the GitHub Actions workflows (deploy, migrate, seed, delete-map)
# through OIDC. It was created by hand and imported.

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

import {
  to = aws_iam_role.github_actions
  id = "github-actions-cicd"
}

import {
  to = aws_iam_role_policy.github_actions_cloudfront
  id = "github-actions-cicd:github-actions-cicd"
}

import {
  to = aws_iam_role_policy.github_actions_lambda_deploy
  id = "github-actions-cicd:lambda-deploy"
}

data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only workflows running on main can deploy.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:sakuro/pasta_atlas:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-cicd"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
}

data "aws_iam_policy_document" "github_actions_cloudfront" {
  statement {
    actions   = ["cloudfront:ListDistributions", "cloudfront:CreateInvalidation"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions_cloudfront" {
  name   = "github-actions-cicd"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_cloudfront.json
}

data "aws_iam_policy_document" "github_actions_lambda_deploy" {
  statement {
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:GetFunctionConfiguration",
      "lambda:InvokeFunction",
    ]
    resources = [
      aws_lambda_function.app.arn,
      aws_lambda_function.task.arn,
      aws_lambda_function.s3_cleanup.arn,
    ]
  }

  statement {
    actions = ["s3:PutObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.lambda_artifacts.arn,
      "${aws_s3_bucket.lambda_artifacts.arn}/*",
      aws_s3_bucket.assets.arn,
      "${aws_s3_bucket.assets.arn}/*",
    ]
  }

  # update-function-code with --s3-bucket/--s3-key reads the object as the caller.
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.lambda_artifacts.arn}/*"]
  }
}

resource "aws_iam_role_policy" "github_actions_lambda_deploy" {
  name   = "lambda-deploy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_lambda_deploy.json
}
