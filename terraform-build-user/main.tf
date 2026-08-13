module "iam_user" {
  source = "github.com/cisagov/ami-build-iam-user-tf-module"

  providers = {
    aws            = aws
    aws.images-ami = aws.images-ami
    aws.images-ssm = aws.images-ssm
  }

  # This image can take a while to build, so we set the max session
  # duration to 2 hours.
  ec2amicreate_role_max_session_duration = 2 * 60 * 60
  ssm_parameters = [
    # Necessary to install the private repository
    # asmtlab/BoundaryIssues.
    "/github/asmtlab/BoundaryIssues",
    "/gitlab/personal_authorization_token",
    "/neo4j/password",
    "/third_party_bucket_name",
    "/vnc/password",
    "/vnc/ssh/ed25519_private_key",
    "/vnc/ssh/ed25519_public_key",
    "/vnc/username",
    # Necessary when building any instances that run the Wazuh agent
    "/wazuh_agent/manager",
  ]
  user_name = "build-kali-packer"
}

# Attach 3rd party S3 bucket read-only policy from
# cisagov/ansible-role-cobalt-strike to the EC2AMICreate role
resource "aws_iam_role_policy_attachment" "thirdpartybucketread_cobaltstrike" {
  provider = aws.images-ami

  policy_arn = data.terraform_remote_state.ansible_role_cobalt_strike.outputs.bucket_access_policy.arn
  role       = module.iam_user.ec2amicreate_role.name
}

# Attach 3rd party S3 bucket read-only policy from
# cisagov/ansible-role-burp-suite-pro to the EC2AMICreate role
resource "aws_iam_role_policy_attachment" "thirdpartybucketread_bsp" {
  provider = aws.images-ami

  policy_arn = data.terraform_remote_state.ansible_role_burp_suite_pro.outputs.bucket_access_policy.arn
  role       = module.iam_user.ec2amicreate_role.name
}
