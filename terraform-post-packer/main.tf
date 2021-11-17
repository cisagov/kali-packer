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

  # Calculate what the names of the accounts that are allowed to use
  # this AMI should look like.  In this case the only accounts that
  # are allowed to use this AMI are the env* accounts of the same type
  # (production, staging, etc.) as the Images account.
  images_account_type = trim(split("(", local.images_account_name)[1], ")")
  account_name_regex  = format("^env[[:digit:]]+ \\(%s\\)$", local.images_account_type)
}

# The IDs of all cisagov/kali-packer AMIs
data "aws_ami_ids" "historical_amis" {
  filter {
    name = "name"
    values = [
      "kali-hvm-*-x86_64-ebs",
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

  owners = [data.aws_caller_identity.images.account_id]
}

# Assign launch permissions to the AMI
module "ami_launch_permission" {
  # Really we only want the var.recent_ami_count most recent AMIs, but
  # we have to cover the case where there are fewer than that many
  # AMIs in existence.  Hence the min()/length() tomfoolery.
  for_each = toset(slice(data.aws_ami_ids.historical_amis.ids, 0, min(var.recent_ami_count, length(data.aws_ami_ids.historical_amis.ids))))

  source = "github.com/cisagov/ami-launch-permission-tf-module"

  providers = {
    aws        = aws
    aws.master = aws.master
  }

  account_name_regex   = local.account_name_regex
  ami_id               = each.value
  extraorg_account_ids = var.extraorg_account_ids
}
