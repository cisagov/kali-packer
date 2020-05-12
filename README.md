# skeleton-packer 💀📦 #

[![GitHub Build Status](https://github.com/cisagov/skeleton-packer/workflows/build/badge.svg)](https://github.com/cisagov/skeleton-packer/actions)

This is a generic skeleton project that can be used to quickly get a
new [cisagov](https://github.com/cisagov) GitHub
[Packer](https://packer.io) project started. This skeleton project
contains [licensing information](LICENSE), as well as
[pre-commit hooks](https://pre-commit.com) and
[GitHub Actions](https://github.com/features/actions) configurations
appropriate for the major languages that we use.

## Pre-requisites ##

This project requires a build user to exist in AWS. The accompanying Terraform
code will create the user with the appropriate name and permissions. This only
needs to be run once per project, per AWS account. This user will also be used
by GitHub Actions.

Before the build user can be created, the following profile must exist in
your AWS credentials file:

* `cool-terraform-backend`

The easiest way to set up that profile is to use our
[`aws-profile-sync`](https://github.com/cisagov/aws-profile-sync) utility.
Follow the usage instructions in that repository before continuing with the
next steps. Note that you will need to know where your team stores their
remote profile data in order to use
[`aws-profile-sync`](https://github.com/cisagov/aws-profile-sync).

To create the build user, follow these instructions:

```console
cd terraform-build-user
terraform init --upgrade=true
terraform apply
```

Once the user is created you will need to update the
[repository's secrets](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets)
with the new encrypted environment variables. This should be done using the
[`terraform-to-secrets`](https://github.com/cisagov/development-guide/tree/develop/project_setup#terraform-iam-credentials-to-github-secrets-)
tool available in the
[development guide](https://github.com/cisagov/development-guide). Instructions
for how to use this tool can be found in the
["Terraform IAM Credentials to GitHub Secrets" section](https://github.com/cisagov/development-guide/tree/develop/project_setup#terraform-iam-credentials-to-github-secrets-).
of the Project Setup README.

If you have appropriate permissions for the repository you can view existing
secrets on the
[appropriate page](https://github.com/cisagov/skeleton-packer/settings/secrets)
in the repository's settings.

IMPORTANT: The account where your images will be built must have a VPC and
a public subnet both tagged with the name "AMI Build", otherwise `packer`
will not be able to build images.

## Building the Image ##

### Using GitHub Actions ###

1. Create a [new release](https://help.github.com/en/articles/creating-releases)
   in GitHub.
1. There is no step 2!

GitHub Actions can build this project in three different modes depending on
how the build was triggered from GitHub.

1. **Non-release test**: After a normal commit or pull request GitHub Actions
   will build the project, and run tests and validation on the
   packer configuration. It will __not__ build an image.
1. **Pre-release deploy**: Publish a GitHub release
   with the "This is a pre-release" checkbox checked. An image will be built
   and deployed using the [`prerelease`](.github/workflows/prerelease.yml)
   workflow. This should be configured to deploy the image to a single region
   using a non-production account (e.g. "staging").
1. **Production release deploy**: Publish a GitHub release with
   the "This is a pre-release" checkbox unchecked. An image will be built
   and deployed using the [`release`](.github/workflows/release.yml)
   workflow. This should be configured to deploy the image to multiple regions
   using a production account.

### Using Your Local Environment ###

Packer will use your
[standard AWS environment](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)
to build the image, however you will need to set up one profile for the
previously-created build user and another profile to assume the associated
`EC2AMICreate` role. You will need the `aws_access_key_id` and
`aws_secret_access_key` that you set as GitHub secrets earlier.

Add the following blocks to your AWS credentials file (be sure to replace the
dummy account ID in the `role_arn` with your own):

```console
[build-skeleton-packer]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

[cool-images-ec2amicreate-skeleton-packer]
role_arn = arn:aws:iam::111111111111:role/EC2AMICreate-build-skeleton-packer
source_profile = build-skeleton-packer
role_session_name = example
```

The [Packer template](src/packer.json) requires two environment variables to be defined:

* `BUILD_REGION`: The region in which to build the image.
* `BUILD_REGION_KMS`: The KMS key alias to use to encrypt the image.

Additionally, the following optional environment variables can be used
by the [Packer template](src/packer.json) to tag the final image:

* `GITHUB_IS_PRERELEASE`: Boolean pre-release status.
* `GITHUB_RELEASE_TAG`: Image version.
* `GITHUB_RELEASE_URL`: URL pointing to the related GitHub release.

Here is an example of how to kick off a pre-release build:

```console
pip install --requirement requirements-dev.txt
ansible-galaxy install --force --force-with-deps --role-file src/requirements.yml
export BUILD_REGION="us-east-1"
export BUILD_REGION_KMS="alias/cool-amis"
export GITHUB_RELEASE_TAG=$(./bump_version.sh show)
AWS_PROFILE=cool-images-ec2amicreate-skeleton-packer packer build --timestamp-ui src/packer.json
```

If you are satisfied with your pre-release image, you can easily create a release
that deploys to all regions by adding additional regions to the packer configuration.
This can be done with the `patch_packer_config.py` helper script.
Echo in a comma-separated regions:kms_keys list to `patch_packer_config.py`
and rerunning packer:

```console
echo "us-east-2:alias/cool-amis,us-west-1:alias/cool-amis,\
us-west-2:alias/cool-amis" | ./patch_packer_config.py src/packer.json
AWS_PROFILE=cool-images-ec2amicreate-skeleton-packer packer build --timestamp-ui src/packer.json
```

See the patcher script's help for more information about its options and
inner workings:

```console
./patch_packer_config.py --help
```

### Giving Other AWS Accounts Permission to Launch the Image ###

After the AMI has been successfully created, you may want to allow other
accounts in your AWS organization permission to launch it. For this project,
we want to allow all accounts whose names begin with "env" to launch the
most-recently-created AMI. To do that, follow these instructions, noting that
"ENVIRONMENT_TYPE" below should be replaced with where the AMI was created
(e.g "production", "staging", etc.):

```console
cd terraform-post-packer
terraform workspace select ENVIRONMENT_TYPE
terraform init --upgrade=true
terraform apply
```

## Contributing ##

We welcome contributions!  Please see [here](CONTRIBUTING.md) for
details.

## License ##

This project is in the worldwide [public domain](LICENSE).

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain
dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.
