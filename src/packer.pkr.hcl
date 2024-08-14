packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.2"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1.1"
    }
  }
  # The required_plugins section is only supported in Packer 1.7.0 and
  # later.  We also want to avoid jumping to Packer v2 until we are
  # ready.
  required_version = "~> 1.7"
}

variable "ami_regions" {
  default     = []
  description = "The list of AWS regions to copy the AMI to once it has been created. Example: [\"us-east-1\"]"
  type        = list(string)
}

# Note: This is only defined as an optional variable because of a current
# limitation in the cisagov/pre-commit-packer hook. Please see
# https://github.com/cisagov/pre-commit-packer/issues/16 for the status of
# that effort.
variable "build_bucket" {
  default     = ""
  description = "The S3 bucket containing the Cobalt Strike and Burp Suite Pro installers."
  type        = string
}

variable "build_region" {
  default     = "us-east-1"
  description = "The region in which to retrieve the base AMI from and build the new AMI."
  type        = string
}

variable "build_region_kms" {
  default     = "alias/cool-amis"
  description = "The ID or ARN of the KMS key to use for AMI encryption."
  type        = string
}

variable "is_prerelease" {
  default     = false
  description = "The pre-release status to use for the tags applied to the created AMI."
  type        = bool
}

variable "region_kms_keys" {
  default     = {}
  description = "A map of regions to copy the created AMI to and the KMS keys to use for encryption in that region. The keys for this map must match the values provided to the aws_regions variable. Example: {\"us-east-1\": \"alias/example-kms\"}"
  type        = map(string)
}

variable "release_tag" {
  default     = ""
  description = "The GitHub release tag to use for the tags applied to the created AMI."
  type        = string
}

variable "release_url" {
  default     = ""
  description = "The GitHub release URL to use for the tags applied to the created AMI."
  type        = string
}

variable "skip_create_ami" {
  default     = false
  description = "Indicate if Packer should not create the AMI."
  type        = bool
}

# There is no ARM-based official Kali AMI in the AWS AMI Catalog.
# data "amazon-ami" "kali_arm64" {
#   filters = {
#     architecture        = "arm64"
#     name                = "kali-last-snapshot-arm64-2023.3.0-*"
#     root-device-type    = "ebs"
#     virtualization-type = "hvm"
#   }
#   most_recent = true
#   owners      = ["679593333241"]
#   region      = var.build_region
# }

data "amazon-ami" "kali_x86_64" {
  filters = {
    architecture        = "x86_64"
    name                = "kali-last-snapshot-amd64-2023.3.0-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["679593333241"]
  region      = var.build_region
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

# There is no ARM-based official Kali AMI in the AWS AMI Catalog.
# source "amazon-ebs" "arm64" {
#   ami_name                    = "kali-hvm-${local.timestamp}-arm64-ebs"
#   ami_regions                 = var.ami_regions
#   associate_public_ip_address = true
#   encrypt_boot                = true
#   instance_type               = "t4g.small"
#   kms_key_id                  = var.build_region_kms
#   launch_block_device_mappings {
#     delete_on_termination = true
#     device_name           = "/dev/xvda"
#     encrypted             = true
#     volume_size           = 30
#     volume_type           = "gp3"
#   }
#   region             = var.build_region
#   region_kms_key_ids = var.region_kms_keys
#   skip_create_ami    = var.skip_create_ami
#   source_ami         = data.amazon-ami.kali_arm64.id
#   ssh_username       = "kali"
#   subnet_filter {
#     filters = {
#       "tag:Name" = "AMI Build"
#     }
#   }
#   tags = {
#     Application        = "Kali"
#     Architecture       = "arm64"
#     Base_AMI_Name      = data.amazon-ami.kali_arm64.name
#     GitHub_Release_URL = var.release_url
#     OS_Version         = "Kali Linux"
#     Pre_Release        = var.is_prerelease
#     Release            = var.release_tag
#     Team               = "VM Fusion - Development"
#   }
#   # Many Linux distributions are now disallowing the use of RSA keys,
#   # so it makes sense to use an ED25519 key instead.
#   temporary_key_pair_type = "ed25519"
#   vpc_filter {
#     filters = {
#       "tag:Name" = "AMI Build"
#     }
#   }
# }

source "amazon-ebs" "x86_64" {
  ami_name                    = "kali-hvm-${local.timestamp}-x86_64-ebs"
  ami_regions                 = var.ami_regions
  associate_public_ip_address = true
  encrypt_boot                = true
  instance_type               = "t3.xlarge"
  kms_key_id                  = var.build_region_kms
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = true
    volume_size           = 30
    volume_type           = "gp3"
  }
  region             = var.build_region
  region_kms_key_ids = var.region_kms_keys
  skip_create_ami    = var.skip_create_ami
  source_ami         = data.amazon-ami.kali_x86_64.id
  ssh_username       = "kali"
  subnet_filter {
    filters = {
      "tag:Name" = "AMI Build"
    }
  }
  tags = {
    Application        = "Kali"
    Architecture       = "x86_64"
    Base_AMI_Name      = data.amazon-ami.kali_x86_64.name
    GitHub_Release_URL = var.release_url
    OS_Version         = "Kali Linux"
    Pre_Release        = var.is_prerelease
    Release            = var.release_tag
    Team               = "VM Fusion - Development"
  }
  # Many Linux distributions are now disallowing the use of RSA keys,
  # so it makes sense to use an ED25519 key instead.
  temporary_key_pair_type = "ed25519"
  vpc_filter {
    filters = {
      "tag:Name" = "AMI Build"
    }
  }
}

build {
  sources = [
    # There is no ARM-based official Kali AMI in the AWS AMI Catalog.
    # "source.amazon-ebs.arm64",
    "source.amazon-ebs.x86_64",
  ]

  provisioner "ansible" {
    playbook_file = "src/upgrade.yml"
    use_proxy     = false
    use_sftp      = true
  }

  provisioner "ansible" {
    playbook_file = "src/python.yml"
    use_proxy     = false
    use_sftp      = true
  }

  provisioner "ansible" {
    ansible_env_vars = ["AWS_DEFAULT_REGION=${var.build_region}"]
    extra_arguments  = ["--extra-vars", "{build_bucket: ${var.build_bucket}}"]
    playbook_file    = "src/playbook.yml"
    use_proxy        = false
    use_sftp         = true
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo env {{ .Vars }} {{ .Path }} ; rm -f {{ .Path }}"
    inline          = ["sed -i '/^users:/ {N; s/users:.*/users: []/g}' /etc/cloud/cloud.cfg", "rm --force /etc/sudoers.d/90-cloud-init-users", "rm --force /root/.ssh/authorized_keys", "/usr/sbin/userdel --remove --force kali"]
    skip_clean      = true
  }
}
