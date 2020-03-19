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

# ------------------------------------------------------------------------------
# Retrieve the information for all accounts in the organization.  This is used to lookup
# the Images account ID for use in the calculation of the related env account names.
# ------------------------------------------------------------------------------
data "aws_organizations_organization" "cool" {
  provider = aws.master
}

# ------------------------------------------------------------------------------
# Evaluate expressions for use throughout this configuration.
# ------------------------------------------------------------------------------
locals {
  # Find the Images account by id.
  images_account_name = [
    for x in data.aws_organizations_organization.cool.accounts :
    x.name if x.id == data.aws_caller_identity.images.account_id
  ][0]

  # Calculate what the environment account names should look like.  This
  # assumes that the images account name is one word long, and any additional
  # words are modifiers.
  # Examples:
  # Images -> "^env[[:digit:]]+$"
  # Images Staging -> "^env[[:digit:]]+ Staging$"
  # Images Alpha Testing -> "^env[[:digit:]]+ Alpha Testing$"
  images_account_prefix = split(" ", local.images_account_name)[0]
  images_account_suffix = trimprefix(local.images_account_name, local.images_account_prefix)
  account_name_regex    = format("^env[[:digit:]]+%s$", local.images_account_suffix)
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

  account_name_regex = local.account_name_regex
  ami_id             = data.aws_ami.example.id
}
