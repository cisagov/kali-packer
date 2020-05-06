# Retrieve the effective Account ID, User ID, and ARN in which Terraform is
# authorized.  This is used to calculate the session names for assumed roles.
data "aws_caller_identity" "terraform_backend" {
  provider = aws.cool-terraform-backend
}
