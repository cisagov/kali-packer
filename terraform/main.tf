# Configure AWS
provider "aws" {
  region = "us-east-1"
}

module "iam_user" {
  source = "github.com/cisagov/aws-parameter-store-read-only-iam-user-tf-module"

  add_packer_permissions = true
  ssm_parameters         = ["/cyhy/dev/users", "/ssh/public_keys/*"]
  user_name              = "test-skeleton-packer"
  tags = {
    Team        = "NCATS OIS - Development"
    Application = "skeleton-packer"
  }
}
