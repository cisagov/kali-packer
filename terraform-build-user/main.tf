module "iam_user" {
  source = "github.com/cisagov/ami-build-iam-user-tf-module"

  providers = {
    aws                       = aws
    aws.images-production-ami = aws.images-production-ami
    aws.images-staging-ami    = aws.images-staging-ami
    aws.images-production-ssm = aws.images-production-ssm
    aws.images-staging-ssm    = aws.images-staging-ssm
  }

  # This image can take a while to build, so we set the max session
  # duration to 2 hours.
  ec2amicreate_role_max_session_duration = 2 * 60 * 60
  ssm_parameters = [
    "/cyhy/dev/users",
    "/gitlab/personal_authorization_token",
    "/neo4j/password",
    "/ssh/public_keys/*",
    "/vnc/password",
    "/vnc/ssh/rsa_private_key",
    "/vnc/ssh/rsa_public_key",
    "/vnc/username",
  ]
  user_name = "build-kali-packer"
  tags = {
    Team        = "CISA - Development"
    Application = "kali-packer"
  }
}
