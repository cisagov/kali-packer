# Use aws_caller_identity with the default provider (Images account)
# so we can provide the Images account ID below
data "aws_caller_identity" "images" {
}

# There is no ARM-based official Kali AMI in the AWS AMI Catalog.
# The IDs of all ARM64 cisagov/kali-packer AMIs
# data "aws_ami_ids" "historical_amis_arm64" {
#   owners = [data.aws_caller_identity.images.account_id]
#
#   filter {
#     name   = "architecture"
#     values = ["arm64"]
#   }
#
#   filter {
#     name   = "name"
#     values = ["kali-hvm-*-arm64-ebs"]
#   }
#
#   filter {
#     name   = "root-device-type"
#     values = ["ebs"]
#   }
#
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# There is no ARM-based official Kali AMI in the AWS AMI Catalog.
# Assign launch permissions to the ARM64 AMIs
# module "ami_launch_permission_arm64" {
#   # Really we only want the var.recent_ami_count most recent AMIs, but
#   # we have to cover the case where there are fewer than that many
#   # AMIs in existence.  Hence the min()/length() tomfoolery.
#   for_each = toset(slice(data.aws_ami_ids.historical_amis_arm64.ids, 0, min(var.recent_ami_count, length(data.aws_ami_ids.historical_amis_arm64.ids))))
#
#   source = "github.com/cisagov/ami-launch-permission-tf-module"
#
#   providers = {
#     aws        = aws
#     aws.master = aws.master
#   }
#
#   account_name_regex   = var.ami_share_account_name_regex
#   ami_id               = each.value
#   extraorg_account_ids = var.extraorg_account_ids
# }

# The IDs of all x86-64 cisagov/kali-packer AMIs
data "aws_ami_ids" "historical_amis_x86_64" {
  owners = [data.aws_caller_identity.images.account_id]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["kali-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# This moved block allows us to rename the resources at
# aws_ami_ids.historical_amis to aws_ami_ids.historical_amis_x86_64
# instead of destroying and recreating them with a new name.
#
# TODO: Consider removing this moved block when it is no longer
# needed.  See cisagov/skeleton-packer#369 for more details.
moved {
  from = aws_ami_ids.historical_amis
  to   = aws_ami_ids.historical_amis_x86_64
}

# Assign launch permissions to the x86-64 AMIs
module "ami_launch_permission_x86_64" {
  # Really we only want the var.recent_ami_count most recent AMIs, but
  # we have to cover the case where there are fewer than that many
  # AMIs in existence.  Hence the min()/length() tomfoolery.
  for_each = toset(slice(data.aws_ami_ids.historical_amis_x86_64.ids, 0, min(var.recent_ami_count, length(data.aws_ami_ids.historical_amis_x86_64.ids))))

  source = "github.com/cisagov/ami-launch-permission-tf-module"

  providers = {
    aws        = aws
    aws.master = aws.master
  }

  account_name_regex   = var.ami_share_account_name_regex
  ami_id               = each.value
  extraorg_account_ids = var.extraorg_account_ids
}

# This moved block allows us to rename the resources at
# module.ami_launch_permission to module.ami_launch_permission_x86_64
# instead of destroying and recreating them with a new name.
#
# TODO: Consider removing this moved block when it is no longer
# needed.  See cisagov/skeleton-packer#369 for more details.
moved {
  from = module.ami_launch_permission
  to   = module.ami_launch_permission_x86_64
}
