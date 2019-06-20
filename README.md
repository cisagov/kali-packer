# skeleton-packer #

[![Build Status](https://travis-ci.com/cisagov/skeleton-packer.svg?branch=develop)](https://travis-ci.com/cisagov/skeleton-packer)

This is a generic skeleton project that can be used to quickly get a
new [cisagov](https://github.com/cisagov) GitHub
[packer](https://packer.io) project started.
This skeleton project contains [licensing information](LICENSE.md), as
well as [pre-commit hooks](https://pre-commit.com) and a [Travis
CI](https://travis-ci.com) configuration appropriate for the major
languages that we use.

## Building the Image ##

The AMI is built like so:

```bash
ansible-galaxy install --force --role-file src/requirements.yml
```

*NOTE*: TODO add environment variables

```bash
packer build src/packer.json
```

## Contributing ##

We welcome contributions!  Please see [here](CONTRIBUTING.md) for
details.

## License ##

This project is in the worldwide [public domain](LICENSE.md).

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain
dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.
