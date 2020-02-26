# Default AWS provider (EC2AMICreate role in the Images account)
provider "aws" {
  region  = "us-east-1"
  profile = "cool-images-ec2amicreate"
}

# AWS provider for the Master account (OrganizationsReadOnly role)
provider "aws" {
  region  = "us-east-1"
  profile = "cool-master-organizationsreadonly"
  alias   = "master"
}

# Use aws_caller_identity with the default provider (Images account)
# so we can provide the Images account ID below
data "aws_caller_identity" "images" {
}

# The most-recent AMI created by cisagov/skeleton-packer-cool
data "aws_ami" "example" {
  filter {
    name = "name"
    values = [
      "example-hvm-*-x86_64-ebs",
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners      = [data.aws_caller_identity.images.account_id]
  most_recent = true
}

# Assign launch permissions to the AMI
module "ami_launch_permission" {
  source = "github.com/cisagov/ami-launch-permission-tf-module"

  providers = {
    aws        = aws
    aws.master = aws.master
  }

  account_name_regex = "^env"
  ami_id             = data.aws_ami.example.id
}
