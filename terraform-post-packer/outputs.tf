output "accounts" {
  value       = module.ami_launch_permission.accounts
  description = "A map whose keys are the IDs of the AWS accounts allowed to launch the AMI, and whose values are the aws_ami_launch_permission resources for the corresponding launch permissions."
}
