output "accounts" {
  value       = module.ami_launch_permission.accounts
  description = "A map whose keys are the account names allowed to launch the AMI and whose values are the account IDs and the AMI ID."
}
