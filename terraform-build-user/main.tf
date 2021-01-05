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

# Attach 3rd party S3 bucket read-only policy from
# cisagov/ansible-role-cobalt-strike to the production EC2AMICreate
# role
resource "aws_iam_role_policy_attachment" "thirdpartybucketread_cobaltstrike_production" {
  provider = aws.images-production-ami

  policy_arn = data.terraform_remote_state.ansible_role_cobalt_strike.outputs.production_policy.arn
  role       = module.iam_user.ec2amicreate_role_production.name
}

# Attach 3rd party S3 bucket read-only policy from
# cisagov/ansible-role-cobalt-strike to the staging EC2AMICreate role
resource "aws_iam_role_policy_attachment" "thirdpartybucketread_cobaltstrike_staging" {
  provider = aws.images-staging-ami

  policy_arn = data.terraform_remote_state.ansible_role_cobalt_strike.outputs.staging_policy.arn
  role       = module.iam_user.ec2amicreate_role_staging.name
}

# Attach 3rd party S3 bucket read-only policy from
# cisagov/ansible-role-burp-suite-pro to the production EC2AMICreate
# role
resource "aws_iam_role_policy_attachment" "thirdpartybucketread_bsp_production" {
  provider = aws.images-production-ami

  policy_arn = data.terraform_remote_state.ansible_role_burp_suite_pro.outputs.production_bucket_policy.arn
  role       = module.iam_user.ec2amicreate_role_production.name
}

# Attach 3rd party S3 bucket read-only policy from
# cisagov/ansible-role-burp-suite-pro to the staging EC2AMICreate role
resource "aws_iam_role_policy_attachment" "thirdpartybucketread_bsp_staging" {
  provider = aws.images-staging-ami

  policy_arn = data.terraform_remote_state.ansible_role_burp_suite_pro.outputs.staging_bucket_policy.arn
  role       = module.iam_user.ec2amicreate_role_staging.name
}
