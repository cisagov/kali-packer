module "iam_user" {
  source = "github.com/cisagov/ami-build-iam-user-tf-module"

  providers = {
    aws                       = aws
    aws.images-production-ami = aws.images-production-ami
    aws.images-production-ssm = aws.images-production-ssm
    aws.images-staging-ami    = aws.images-staging-ami
    aws.images-staging-ssm    = aws.images-staging-ssm
  }

  ssm_parameters = ["/cyhy/dev/users", "/ssh/public_keys/*"]
  user_name      = "build-skeleton-packer"
}
