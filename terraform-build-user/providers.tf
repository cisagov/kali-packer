locals {
  # Extract the user name of the caller for use in assumed role session names.
  # When using the value of `user_id` we were unable to assume roles using
  # `caller_user_name` as their `session_name`. The error message returned by AWS
  # did not indicate that the `session_name` was the issue, however when the
  # semicolon was removed there were no issues. Please see the documentation at
  # https://docs.aws.amazon.com/cli/latest/reference/sts/assume-role.html
  # for information about acceptable characters for the session name.
  caller_user_name = replace(data.aws_caller_identity.terraform_backend.user_id, ":", ".")
}

# Provider that is only used for obtaining the caller identity.
# Note that we cannot use a provider that assumes a role via an ARN from a
# Terraform remote state for this purpose (like we do for all of the other
# providers below).  This is because we derive the session name (in the
# assume_role block within the provider) from the caller identity of this
# provider; if we try to do that, it results in a Terraform "Cycle" error.
# Hence, for our caller identity, we use a provider based on a profile that
# must exist for the Terraform backend to work ("cool-terraform-backend").
provider "aws" {
  alias   = "cool-terraform-backend"
  region  = "us-east-1"
  profile = "cool-terraform-backend"
}

# Default AWS provider (ProvisionAccount for the Users account)
provider "aws" {
  region = "us-east-1"
  assume_role {
    role_arn     = data.terraform_remote_state.users.outputs.provisionaccount_role.arn
    session_name = local.caller_user_name
  }
}

# ProvisionEC2AMICreateRoles AWS provider for the Images Production account
provider "aws" {
  alias  = "images-production-ami"
  region = "us-east-1"
  assume_role {
    role_arn     = data.terraform_remote_state.images_production.outputs.provisionec2amicreateroles_role.arn
    session_name = local.caller_user_name
  }
}

# ProvisionParameterStoreReadRoles AWS provider for the Images Production account
provider "aws" {
  alias  = "images-production-ssm"
  region = "us-east-1"
  assume_role {
    role_arn     = data.terraform_remote_state.images_parameterstore_production.outputs.provisionparameterstorereadroles_role.arn
    session_name = local.caller_user_name
  }
}

# ProvisionEC2AMICreateRoles AWS provider for the Images Staging account
provider "aws" {
  alias  = "images-staging-ami"
  region = "us-east-1"
  assume_role {
    role_arn     = data.terraform_remote_state.images_staging.outputs.provisionec2amicreateroles_role.arn
    session_name = local.caller_user_name
  }
}

# ProvisionParameterStoreReadRoles AWS provider for the Images Staging account
provider "aws" {
  alias  = "images-staging-ssm"
  region = "us-east-1"
  assume_role {
    role_arn     = data.terraform_remote_state.images_parameterstore_staging.outputs.provisionparameterstorereadroles_role.arn
    session_name = local.caller_user_name
  }
}
