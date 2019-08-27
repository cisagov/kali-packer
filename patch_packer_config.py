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

There are three modes of operation: pre-release, release, and query-github.  The
first two modes are self-explanatory.

When invoked with the query-github command the TRAVIS_REPO_SLUG and TRAVIS_TAG
environment variables are used to determine if the current build is a
pre-release using the GitHub API.

Note: when running in a Travis CI it is possible that the GitHub API call will
be rate limited by the shared IP of all Travis users.  Setting the
GITHUB_ACCESS_TOKEN will cause this script to be limited by the token owner's
account instead.

See: https://developer.github.com/v3/#rate-limiting

Usage:
    patch_packer_config.py (query-github|pre-release|release) <packer-json>
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
from github import Github
from github.GithubException import UnknownObjectException

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


def query_github():
    """Query GitHub to see if this release is a pre-release."""
    travis_tag = os.getenv("TRAVIS_TAG")
    if not travis_tag:
        eprint("TRAVIS_TAG not set (not a release)")
        # The config still needs to be generated correctly as
        # it will be validated even if it isn't deployed.
        # So we'll generate it as if it was a full release since
        # it will test more of the configuration.
        return False

    travis_repo_slug = os.getenv("TRAVIS_REPO_SLUG")
    if not travis_repo_slug:
        eprint("TRAVIS_REPO_SLUG not set. (required for query-github mode)")
        sys.exit(-1)

    access_token = os.getenv("GITHUB_ACCESS_TOKEN")
    # if we have a Github access token use it, otherwise we may be rate limited
    # by all the other Travis users coming from the same IP.
    if access_token:
        git = Github(access_token)
        eprint(f"Using GITHUB_ACCESS_TOKEN to access GitHub API.")
    else:
        git = Github()
        eprint(
            f"Warning: GITHUB_ACCESS_TOKEN not set.  "
            + "GitHub API access can easily fail if using a shared egress IP."
        )
    try:
        repo = git.get_repo(travis_repo_slug)
        release = repo.get_release(travis_tag)
        if release.prerelease:
            eprint(f"GitHub says {travis_tag} is a pre-release build.")
        else:
            eprint(f"GitHub says {travis_tag} is NOT a pre-release build.")
        return release.prerelease
    except UnknownObjectException:
        # Either the travis_repo_slug or travis_tag were not found.
        eprint(
            f"Unable to lookup pre-release status for {travis_repo_slug}:{travis_tag}"
        )
        sys.exit(-1)


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
        builder["tags"]["Pre_Release"] = str(is_prerelease)
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

    if args["query-github"]:
        is_prerelease = query_github()
    elif args["pre-release"]:
        eprint(f"User requested a pre-release build.")
        is_prerelease = True
    else:  # release (enforced by docopt)
        eprint(f"User requested a release build.")
        is_prerelease = False

    patch_config(config_filename, build_region, kms_map, is_prerelease)

    sys.exit(0)


if __name__ == "__main__":
    main()
