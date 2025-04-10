# Build User #

This directory consists of [Terraform](https://www.terraform.io/) code
that is used to create a build user.  This build user is in turn used
by our CI/CD pipeline to create AMIs via [Packer](https://packer.io)
for our various COOL environments.

See [the overall project documentation](../README.md) for a detailed
description of how this code is intended to be used.

<!-- BEGIN_TF_DOCS -->
## Requirements ##

| Name | Version |
|------|---------|
| terraform | ~> 1.0 |
| aws | ~> 4.9 |

## Providers ##

| Name | Version |
|------|---------|
| aws.cool-terraform-backend | ~> 4.9 |
| terraform | n/a |

## Modules ##

| Name | Source | Version |
|------|--------|---------|
| iam\_user | github.com/cisagov/ami-build-iam-user-tf-module | n/a |

## Resources ##

| Name | Type |
|------|------|
| [aws_caller_identity.terraform_backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [terraform_remote_state.images](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.images_parameterstore](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.users](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs ##

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| terraform\_state\_bucket | The name of the S3 bucket where Terraform state is stored. | `string` | n/a | yes |

## Outputs ##

No outputs.
<!-- END_TF_DOCS -->
