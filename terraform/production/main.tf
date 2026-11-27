terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.45"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    gandi = {
      source  = "go-gandi/gandi"
      version = "~> 2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }

  # The organization and workspace come from TF_CLOUD_ORGANIZATION and TF_WORKSPACE, which fnox.toml
  # and the terraform:* tasks supply.
  cloud {}
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

provider "cloudflare" {}

data "cloudflare_zone" "main" {
  filter = {
    name = var.cloudflare_zone_name
  }
}
