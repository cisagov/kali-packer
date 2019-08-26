#!/usr/bin/env python
"""Modify a packer json configuration based on the build environment.

This script uses the GitHub API and the TRAVIS_REPO_SLUG and TRAVIS_TAG environment
variables to determine if the current build is a pre-release.  It will then modify
the passed in Packer configuration.

When running in a Travis CI it is possible that the GitHub API call will be rate
limited by the shared IP of all Travis users.  Setting the GITHUB_ACCESS_TOKEN
will cause this script to be limited by the token owner instead.

See: https://developer.github.com/v3/#rate-limiting

It reads the PACKER_BUILD_REGION and PACKER_DEPLOY_REGION_KMS_MAP environment
variables to calculate the values in the packer configuration.

Example usage:
    ./patch_packer_config.py src/packer.json
"""

import json
import os
import sys

from github import Github
from github.GithubException import UnknownObjectException


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


def patch_config(filename, build_region, kms_map, is_prerelease):
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
        builder["tags"]["Pre_Release"] = is_prerelease
        builder["region"] = build_region

        if is_prerelease:
            # Pre-Release
            builder["ami_regions"] = build_region
            builder["region_kms_key_ids"] = {build_region: kms_map[build_region]}
        else:
            # Production Release
            builder["ami_regions"] = ",".join(kms_map.keys())
            builder["region_kms_key_ids"] = kms_map

    # write the modified configuration back out
    with open(filename, "w") as fp:
        json.dump(config, fp, indent=2, sort_keys=True)


def main():
    """Check pre-release flag and return value for PACKER_DEPLOY_REGIONS."""
    try:
        config_filename = sys.argv[1]
    except IndexError:
        eprint(f"Packer configuration file name not provided.")
        sys.exit(-1)

    # if we have a Github access token use it, otherwise we may be rate limited
    # by all the other Travis users coming from the same IP.
    access_token = os.getenv("GITHUB_ACCESS_TOKEN")
    if access_token:
        g = Github(access_token)
    else:
        g = Github()

    build_region = os.getenv("PACKER_BUILD_REGION")
    if not build_region:
        eprint("PACKER_BUILD_REGION not set")
        sys.exit(-1)

    kms_map_string = os.getenv("PACKER_DEPLOY_REGION_KMS_MAP")
    if not kms_map_string:
        eprint("PACKER_DEPLOY_REGION_KMS_MAP not set")
        sys.exit(-1)
    kms_map = make_kms_map(kms_map_string)

    slug = os.getenv("TRAVIS_REPO_SLUG")
    if not slug:
        eprint("TRAVIS_REPO_SLUG not set")
        sys.exit(-1)

    tag = os.getenv("TRAVIS_TAG")
    if not tag:
        eprint("TRAVIS_TAG not set (not a release)")
        is_prerelease = False
    else:
        try:
            repo = g.get_repo(slug)
            release = repo.get_release(tag)
            is_prerelease = release.prerelease
        except UnknownObjectException:
            # Either the slug or tag were not found.
            eprint(f"Unable to lookup pre-release status for {slug}:{tag}")
            sys.exit(-1)

    if is_prerelease:
        # This is a prerelease: no PACKER_DEPLOY_REGIONS.
        eprint(f"{tag} is a pre-release build.")
    else:
        # This is a regular release: do not modify PACKER_DEPLOY_REGIONS.
        eprint(f"{tag} is NOT a pre-release build.")

    patch_config(config_filename, build_region, kms_map, is_prerelease)

    sys.exit(0)


if __name__ == "__main__":
    main()
