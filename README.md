# kali-packer :dragon:📦 #

[![Build Status](https://travis-ci.com/cisagov/kali-packer.svg?branch=develop)](https://travis-ci.com/cisagov/kali-packer)

This project can be used to create machine images that include
[Kali Linux](https://www.kali.org), a Linux Penetration Testing Distribution.

## Pre-requisites ##

This project requires a build user to exist in AWS.  The accompanying terraform
code will create the user with the appropriate name and permissions.  This only
needs to be run once per project, per AWS account.  This user will also be used by
Travis-CI.

```console
cd terraform
terraform init --upgrade=true
terraform apply
```

Once the user is created you will need to update the `.travis.yml` file with the
new encrypted environment variables.

```console
terraform state show module.iam_user.aws_iam_access_key.key
```

Take the `id` and `secret` fields from the above command's output and [encrypt
and place in the `.travis.yml` file](https://docs.travis-ci.com/user/encryption-keys/).

Here is an example of encrypting the credentials for Travis:

```console
 travis encrypt --com --no-interactive "AWS_ACCESS_KEY_ID=AKIAxxxxxxxxxxxxxxxx"
 travis encrypt --com --no-interactive "AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

## Building the Image ##

### Using Travis-CI ###

1. Create a new release in GitHub.
1. There is no step 2!

### Using Your Local Environment ###

The following environment variables are used by Packer:

- Required
  - `PACKER_BUILD_REGION`: the region to build the build the image in.
- Optional
  - `PACKER_DEPLOY_REGIONS`: list of additional regions to deploy this image.
  - `PACKER_IMAGE_VERSION`: the version tag applied to the final image.
  - `PACKER_PRE_RELEASE`: a boolean tag applied to the final image

Here is an example of how to kick off a build:

```console
export PACKER_BUILD_REGION="us-east-2"
export PACKER_DEPLOY_REGIONS="us-east-1,us-west-1,us-west-2"
export PACKER_IMAGE_VERSION=$(./bump_version.sh show)
export PACKER_PRE_RELEASE="True"
pip install --requirement requirements-dev.txt
ansible-galaxy install --force --role-file src/requirements.yml
packer build --timestamp-ui src/packer.json
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
