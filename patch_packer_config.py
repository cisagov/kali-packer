#!/usr/bin/env python
"""Modify a packer json configuration deploy regions and KMS keys.

This script reads the REGION_KMS_MAP environment variable to calculate
the values for the packer configuration.

It will overwrite the following sections of a packer amazon-ebs builder
configuration:
 - ami_regions
 - region_kms_key_ids

Usage:
    patch_packer_config.py <packer-json>
    patch_packer_config.py -h | --help
    patch_packer_config.py -v | --version

Options:
  -h --help              Show this message.
  -v --version           Output the version of the script.
"""

import json
import os
import sys

import docopt

__version__ = "1.1.0"


def eprint(*args, **kwargs):
    """Print to stderr."""
    print(*args, file=sys.stderr, **kwargs)


def make_kms_map(map_string):
    """Convert a string into a map."""
    # The one line version:
    # dict({tuple(k.split(':')) for k in [i.strip() for i in m.split(',')]})
    result = dict()
    # split string by comma and strip
    lines = [i.strip() for i in map_string.split(",")]
    for line in lines:
        # split into key/value pairs and store
        k, v = line.split(":")
        result[k] = v
    return result


def patch_config(filename, kms_map):
    """Patch the packer configuration file."""
    try:
        # read and parse the packer configuration file
        with open(filename, "r") as fp:
            config = json.load(fp)
    except FileNotFoundError:
        eprint(f"Packer configuration file not found: {filename}")
        sys.exit(-1)

    # loop through all the packer builders
    for builder in config["builders"]:
        # only modify AWS builders
        if builder.get("type") != "amazon-ebs":
            continue
        builder["ami_regions"] = ",".join(kms_map.keys())
        builder["region_kms_key_ids"] = kms_map

    # write the modified configuration back out
    with open(filename, "w") as fp:
        json.dump(config, fp, indent=2, sort_keys=True)


def main():
    """Modify a packer configuration file."""
    args = docopt.docopt(__doc__, version=__version__)

    config_filename = args["<packer-json>"]

    kms_map_string = os.getenv("REGION_KMS_MAP")
    if not kms_map_string:
        eprint("REGION_KMS_MAP not set (required)")
        sys.exit(-1)
    kms_map = make_kms_map(kms_map_string)

    patch_config(config_filename, kms_map)

    sys.exit(0)


if __name__ == "__main__":
    main()
