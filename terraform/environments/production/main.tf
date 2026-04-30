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

  backend "s3" {
    bucket       = "sakuro-terraform-state"
    key          = "pasta-atlas/production/terraform.tfstate"
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true
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

module "mapshots" {
  source = "../../module/mapshots"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
    gandi         = gandi
  }

  app_name               = "pasta-atlas"
  environment            = "production"
  maps_domain_name       = "maps.pasta-atlas.layer8.works"
  allowed_origins        = ["https://pasta-atlas.layer8.works"]
  cloudfront_price_class = var.cloudfront_price_class
  presigned_url_expiry   = var.presigned_url_expiry
}

module "backend" {
  source = "../../module/backend"

  providers = {
    aws   = aws
    gandi = gandi
  }

  app_name            = "pasta-atlas"
  environment         = "production"
  app_domain_name     = "pasta-atlas.layer8.works"
  s3_bucket_name      = module.mapshots.s3_bucket_name
  s3_bucket_arn       = module.mapshots.s3_bucket_arn
  cloudfront_base_url = module.mapshots.cloudfront_domain_name
  db_password         = var.db_password
  db_instance_class   = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
}
