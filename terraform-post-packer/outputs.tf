output "launch_permissions" {
  value       = module.ami_launch_permission
  description = "The cisagov/ami-launch-permission-tf-module for each AMI to which launch permission is being granted."
}
