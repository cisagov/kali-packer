# kali-packer 💀📦🆒 #

[![GitHub Build Status](https://github.com/cisagov/kali-packer/workflows/build/badge.svg)](https://github.com/cisagov/kali-packer/actions)

This project can be used to create machine images based on [Kali
Linux](https://www.kali.org), a Linux penetration testing
distribution.

## Pre-requisites ##

This project requires a build user to exist in AWS.  The accompanying
Terraform code will create the user with the appropriate name and
permissions.  This only needs to be run once per project, per AWS
account.  This user will also be used by GitHub Actions.

Before the build user can be created, the following profile must exist
in your AWS credentials file:

- `cool-terraform-backend`

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
[appropriate page](https://github.com/cisagov/kali-packer/settings/secrets)
in the repository's settings.

IMPORTANT: The account where your images will be built must have a VPC
and a public subnet both tagged with the name "AMI Build", otherwise
`packer` will not be able to build images.

This project also requires the following data to exist in your [AWS
Systems Manager parameter
store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html):

- `/cyhy/dev/users`: A comma-separated list of usernames of users that should
  be allowed to SSH to the instance based on this image
- `/ssh/public_keys/<username>`: The public SSH key of each user in the
  `/cyhy/dev/users` list

## Building the Image ##

### Using GitHub Actions ###

1. Create a [new
   release](https://help.github.com/en/articles/creating-releases) in
   GitHub.
1. There is no step 2!

GitHub Actions can build this project in three different modes
depending on how the build was triggered from GitHub.

1. **Non-release test**: After a normal commit or pull request GitHub Actions
   will build the project, and run tests and validation on the
   packer configuration. It will **not** build an image.
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
[build-kali-packer]
aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

[cool-images-ec2amicreate-kali-packer]
role_arn = arn:aws:iam::111111111111:role/EC2AMICreate-build-kali-packer
source_profile = build-kali-packer
role_session_name = example
```

The [Packer template](src/packer.pkr.hcl) defines a number of variables:

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ami\_regions | The list of AWS regions to copy the AMI to once it has been created. Example: ["us-east-1"] | `list(string)` | `[]` | no |
| build\_bucket | The S3 bucket containing the Cobalt Strike and Burp Suite Pro installers. | `string` | `""` | no |
| build\_region | The region in which to retrieve the base AMI from and build the new AMI. | `string` | `"us-east-1"` | no |
| build\_region\_kms | The ID or ARN of the KMS key to use for AMI encryption. | `string` | `"alias/cool-amis"` | no |
| is\_prerelease | The pre-release status to use for the tags applied to the created AMI. | `bool` | `false` | no |
| region\_kms\_keys | A map of regions to copy the created AMI to and the KMS keys to use for encryption in that region. The keys for this map must match the values provided to the aws\_regions variable. Example: {"us-east-1": "alias/example-kms"} | `map(string)` | `{}` | no |
| release\_tag | The GitHub release tag to use for the tags applied to the created AMI. | `string` | `""` | no |
| release\_url | The GitHub release URL to use for the tags applied to the created AMI. | `string` | `""` | no |
| skip\_create\_ami | Indicate if Packer should not create the AMI. | `bool` | `false` | no |

Changing these defaults can be done through a `.pkrvars.hcl` file:

```hcl
build_bucket = "installers-bucket"
build_region = "us-east-2"
build_region_kms = "alias/example-kms"
is_prerelease = "true"
```

Here is an example of how to kick off a pre-release build:

```console
pip install --requirement requirements-dev.txt
ansible-galaxy install --force --force-with-deps --role-file src/requirements.yml
AWS_PROFILE=cool-images-ec2amicreate-kali-packer packer build --timestamp-ui -var release_tag=$(./bump_version.sh show) -var build_bucket="installers-bucket" -var is_prerelease=true src/packer.pkr.hcl
```

If you are satisfied with your pre-release image, you can easily create a release
that deploys to all regions by adding additional regions to the packer configuration.
This can be done by using a `.pkrvars.hcl` for example with `release.pkrvars.hcl`:

```hcl
build_bucket = "installers-bucket"
ami_regions = ["us-east-2", "us-west-1", "us-west-2"]
region_kms_keys = {
  "us-east-2": "alias/cool-amis",
  "us-west-1": "alias/cool-amis",
  "us-west-2": "alias/cool-amis",
}
```

```console
AWS_PROFILE=cool-images-ec2amicreate-kali-packer packer build --timestamp-ui -var-file release.pkrvars.hcl src/packer.pkr.hcl
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

We welcome contributions!  Please see [`CONTRIBUTING.md`](CONTRIBUTING.md) for
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
