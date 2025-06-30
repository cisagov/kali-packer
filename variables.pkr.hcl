# ------------------------------------------------------------------------------
# Required parameters
#
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Optional parameters
#
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------

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

variable "force_install_ansible_requirements" {
  default     = false
  description = "Indicate if the Ansible requirements should be force installed."
  type        = bool
}

variable "force_install_ansible_requirements_with_dependencies" {
  default     = false
  description = "Indicate if the Ansible requirements *and* their dependencies should be force installed."
  type        = bool
}

variable "github_ref_name" {
  default     = ""
  description = "The GitHub short ref name to use for the tags applied to the created AMI."
  type        = string
}

variable "github_sha" {
  default     = ""
  description = "The GitHub commit SHA to use for the tags applied to the created AMI."
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
