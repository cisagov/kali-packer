locals {
  tags = {
    Application = "skeleton-packer"
    Team        = "CISA - Development"
  }
}

# Default AWS provider (EC2AMICreate role in the Images account)
provider "aws" {
  default_tags {
    tags = local.tags
  }
  profile = "cool-images-ec2amicreate"
  region  = "us-east-1"
}

# AWS provider for the Master account (OrganizationsReadOnly role)
provider "aws" {
  alias = "master"
  default_tags {
    tags = local.tags
  }
  profile = "cool-master-organizationsreadonly"
  region  = "us-east-1"
}
