terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    gandi = {
      source  = "go-gandi/gandi"
      version = "~> 2.0"
    }
  }

  cloud {
    organization = "sakuro"

    workspaces {
      name = "pasta-atlas-production"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Project     = "pasta-atlas"
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "pasta-atlas"
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}

provider "gandi" {}
