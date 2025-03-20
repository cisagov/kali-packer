# There is no ARM-based official Kali AMI in the AWS AMI Catalog.
# data "amazon-ami" "kali_arm64" {
#   filters = {
#     architecture        = "arm64"
#     name                = "kali-last-snapshot-arm64-2025.1.0-*"
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
    name                = "kali-last-snapshot-amd64-2025.1.0-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["679593333241"]
  region      = var.build_region
}
