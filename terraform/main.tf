# Default AWS provider (ProvisionAccount for the Users account)
provider "aws" {
  region  = "us-east-1"
  profile = "cool-users-provisionaccount"
}

# ProvisionEC2AMICreateRoles AWS provider for the Images account
provider "aws" {
  region  = "us-east-1"
  profile = "cool-images-provisionec2amicreateroles"
  alias   = "images-ProvisionEC2AMICreateRoles"
}

# ProvisionParameterStoreReadRoles AWS provider for the Images account
provider "aws" {
  region  = "us-east-1"
  profile = "cool-images-provisionparameterstorereadroles"
  alias   = "images-ProvisionParameterStoreReadRoles"
}

# Use aws_caller_identity with the Images account provider so we can pass the
# Images account ID into the module below
data "aws_caller_identity" "images" {
  provider = aws.images-ProvisionParameterStoreReadRoles
}

module "iam_user" {
  source = "github.com/cisagov/molecule-packer-ci-iam-user-tf-module"

  providers = {
    aws                                         = aws
    aws.images-ProvisionEC2AMICreateRoles       = aws.images-ProvisionEC2AMICreateRoles
    aws.images-ProvisionParameterStoreReadRoles = aws.images-ProvisionParameterStoreReadRoles
  }

  add_packer_permissions = true
  images_account_id      = data.aws_caller_identity.images.account_id
  ssm_parameters         = ["/cyhy/dev/users", "/ssh/public_keys/*"]
  user_name              = "test-skeleton-packer-cool"
  tags = {
    Team        = "CISA - Development"
    Application = "skeleton-packer-cool"
  }
}
