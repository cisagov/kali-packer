# ------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
#
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------

variable "extraorg_account_ids" {
  default     = []
  description = "A list of AWS account IDs corresponding to \"extra\" accounts with which you want to share this AMI (e.g. [\"123456789012\"]).  Normally this variable is used to share an AMI with accounts that are not a member of the same AWS Organization as the account that owns the AMI."
  type        = list(string)
}

variable "recent_ami_count" {
  default     = 12
  description = "The number of most-recent AMIs for which to grant launch permission (e.g. \"3\").  If this variable is set to three, for example, then accounts will be granted permission to launch the three most recent AMIs (or all most recent AMIs, if there are only one or two of them in existence)."
  type        = number
}
