# ------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
#
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------

variable "extraorg_account_ids" {
  type        = list(string)
  description = "A list of AWS account IDs corresponding to \"extra\" accounts with which you want to share this AMI (e.g. [\"123456789012\"]).  Normally this variable is used to share an AMI with accounts that are not a member of the same AWS Organization as the account that owns the AMI."
  default     = []
}
