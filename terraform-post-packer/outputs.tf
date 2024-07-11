output "launch_permissions_arm64" {
  value       = module.ami_launch_permission_arm64
  description = "The cisagov/ami-launch-permission-tf-module for each ARM64 AMI to which launch permission is being granted."
}

output "launch_permissions_x86_64" {
  value       = module.ami_launch_permission_x86_64
  description = "The cisagov/ami-launch-permission-tf-module for each x86_64 AMI to which launch permission is being granted."
}
