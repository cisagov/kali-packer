# Post-Packer #

This directory consists of [Terraform](https://www.terraform.io/) code
that is used to share AMIs with the appropriate AWS accounts.  This
code is intended to be run after the CI/CD pipeline has created a new
AMI for a COOL environment.

See [the overall project documentation](../README.md) for more
details.

<!-- BEGIN_TF_DOCS -->
## Requirements ##

| Name | Version |
|------|---------|
| terraform | ~> 1.0 |
| aws | ~> 4.9 |

## Providers ##

| Name | Version |
|------|---------|
| aws | ~> 4.9 |

## Modules ##

| Name | Source | Version |
|------|--------|---------|
| ami\_launch\_permission\_arm64 | github.com/cisagov/ami-launch-permission-tf-module | n/a |
| ami\_launch\_permission\_x86\_64 | github.com/cisagov/ami-launch-permission-tf-module | n/a |

## Resources ##

| Name | Type |
|------|------|
| [aws_ami_ids.historical_amis_arm64](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami_ids) | data source |
| [aws_ami_ids.historical_amis_x86_64](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami_ids) | data source |
| [aws_caller_identity.images](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs ##

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ami\_share\_account\_name\_regex | A regular expression that matches the names of AWS accounts with which to share the AMIs created by this repository.  This variable is used to share the AMIs with accounts that are members of the same AWS Organization as the account that owns the AMIs. | `string` | `"^env[[:digit:]]+$"` | no |
| extraorg\_account\_ids | A list of AWS account IDs corresponding to "extra" accounts with which you want to share this AMI (e.g. ["123456789012"]).  Normally this variable is used to share an AMI with accounts that are not a member of the same AWS Organization as the account that owns the AMI. | `list(string)` | `[]` | no |
| recent\_ami\_count | The number of most-recent AMIs (per architecture) for which to grant launch permission (e.g. "3").  If this variable is set to three, for example, then accounts will be granted permission to launch the three most recent AMIs (or all most recent AMIs, if there are only one or two of them in existence). | `number` | `12` | no |

## Outputs ##

| Name | Description |
|------|-------------|
| launch\_permissions\_arm64 | The cisagov/ami-launch-permission-tf-module for each ARM64 AMI to which launch permission is being granted. |
| launch\_permissions\_x86\_64 | The cisagov/ami-launch-permission-tf-module for each x86\_64 AMI to which launch permission is being granted. |
<!-- END_TF_DOCS -->
