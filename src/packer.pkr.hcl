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
  default     = "false"
  description = "Indicate whether or not the built AMI is a prerelease."
  type        = string
}

variable "release_tag" {
  default     = ""
  description = "The release tag to apply to the built AMI."
  type        = string
}

variable "release_url" {
  default     = ""
  description = "The URL for the release that defines the built AMI."
  type        = string
}

variable "skip_create_ami" {
  default     = "false"
  description = "Indicate if Packer should not create the AMI."
  type        = string
}

data "amazon-ami" "debian_bullseye" {
  filters = {
    name                = "debian-11-amd64-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["136693071363"]
  region      = var.build_region
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "example" {
  ami_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = true
    volume_size           = 8
    volume_type           = "gp3"
  }
  ami_name                    = "example-hvm-${local.timestamp}-x86_64-ebs"
  ami_regions                 = []
  associate_public_ip_address = true
  encrypt_boot                = true
  instance_type               = "t3.small"
  kms_key_id                  = var.build_region_kms
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = true
    volume_size           = 8
    volume_type           = "gp3"
  }
  region             = var.build_region
  region_kms_key_ids = {}
  skip_create_ami    = var.skip_create_ami
  source_ami         = "${data.amazon-ami.debian_bullseye.id}"
  ssh_username       = "admin"
  subnet_filter {
    filters = {
      "tag:Name" = "AMI Build"
    }
  }
  tags = {
    Application        = "Example"
    Base_AMI_Name      = "{{ .SourceAMIName }}"
    GitHub_Release_URL = var.release_url
    OS_Version         = "Debian Bullseye"
    Pre_Release        = var.is_prerelease
    Release            = var.release_tag
    Team               = "VM Fusion - Development"
  }
  vpc_filter {
    filters = {
      "tag:Name" = "AMI Build"
    }
  }
}

build {
  sources = ["source.amazon-ebs.example"]

  provisioner "ansible" {
    playbook_file = "src/upgrade.yml"
  }

  provisioner "ansible" {
    playbook_file = "src/python.yml"
  }

  provisioner "ansible" {
    ansible_env_vars = ["AWS_DEFAULT_REGION=${var.build_region}"]
    playbook_file    = "src/playbook.yml"
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo env {{ .Vars }} {{ .Path }} ; rm -f {{ .Path }}"
    inline          = ["sed -i '/^users:/ {N; s/users:.*/users: []/g}' /etc/cloud/cloud.cfg", "rm --force /etc/sudoers.d/90-cloud-init-users", "rm --force /root/.ssh/authorized_keys", "/usr/sbin/userdel --remove --force admin"]
    skip_clean      = true
  }

}
