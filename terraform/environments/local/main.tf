terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "ap-northeast-1"
  access_key                  = "dummy"
  secret_key                  = "dummy"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  s3_use_path_style = true

  endpoints {
    ec2 = "http://localhost:4566"
    iam = "http://localhost:4566"
    rds = "http://localhost:4566"
    s3  = "http://localhost:4566"
    sqs = "http://localhost:4566"
    ssm = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}
