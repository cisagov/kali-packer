#!/usr/bin/env python
"""Modify a packer json configuration to support pre-releases.

This script reads the PACKER_BUILD_REGION and PACKER_DEPLOY_REGION_KMS_MAP
environment variables to calculate the values for the packer configuration.

It will overwrite the following sections of a packer amazon-ebs builder
configuration:
 - ami_regions
 - region
 - region_kms_key_ids
 - tags/Pre_Release

There are two modes of operation: published, and unpublished (draft).

Usage:
    patch_packer_config.py (published|unpublished) <packer-json>
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

__version__ = "1.0.0"


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


def patch_config(filename, build_region, kms_map, is_draft):
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

        # invariants
        builder["tags"]["Draft"] = str(is_draft)
        builder["region"] = build_region

        if is_draft:
            # Unpublished (draft)
            builder["ami_regions"] = build_region
            builder["region_kms_key_ids"] = {build_region: kms_map[build_region]}
        else:
            # Published Release
            builder["ami_regions"] = ",".join(kms_map.keys())
            builder["region_kms_key_ids"] = kms_map

    # write the modified configuration back out
    with open(filename, "w") as fp:
        json.dump(config, fp, indent=2, sort_keys=True)


def main():
    """Modify a packer configuration file."""
    args = docopt.docopt(__doc__, version=__version__)

    config_filename = args["<packer-json>"]

    build_region = os.getenv("PACKER_BUILD_REGION")
    if not build_region:
        eprint("PACKER_BUILD_REGION not set (required)")
        sys.exit(-1)

    kms_map_string = os.getenv("PACKER_DEPLOY_REGION_KMS_MAP")
    if not kms_map_string:
        eprint("PACKER_DEPLOY_REGION_KMS_MAP not set (required)")
        sys.exit(-1)
    kms_map = make_kms_map(kms_map_string)

    if args["unpublished"]:
        eprint(f"User requested a unpublished (draft) build.")
        is_draft = True
    else:  # published (enforced by docopt)
        eprint(f"User requested a published build.")
        is_draft = False

    patch_config(config_filename, build_region, kms_map, is_draft)

    sys.exit(0)


if __name__ == "__main__":
    main()
