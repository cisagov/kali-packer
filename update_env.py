#!/usr/bin/env python
"""Script to output shell commands needed to update the evironment.

This script uses the GitHub API and the TRAVIS_REPO_SLUG and TRAVIS_TAG environment
variables to determine if the current build is a pre-release.  It will then output
shell commands for evaulation based on the pre-release status.

Exit codes:
    0: This is a pre-release.
   -1: This is a regular release.
   -2: Uset environment variables: TRAVIS_REPO_SLUG or TRAVIS_TAG
   -3: Unable to find the release using the GitHub API

Example usage:
    eval $(./update_env.py)
"""

import os
import sys

from github import Github
from github.GithubException import UnknownObjectException


def eprint(*args, **kwargs):
    """Print to stderr."""
    print(*args, file=sys.stderr, **kwargs)


def main():
    """Check pre-release flag and return value for PACKER_DEPLOY_REGIONS."""
    g = Github()

    slug = os.getenv("TRAVIS_REPO_SLUG")
    if not slug:
        eprint("TRAVIS_REPO_SLUG not set")
        sys.exit(-2)

    tag = os.getenv("TRAVIS_TAG")
    if not tag:
        eprint("TRAVIS_TAG not set")
        sys.exit(-2)

    try:
        repo = g.get_repo(slug)
        release = repo.get_release(tag)
    except UnknownObjectException:
        # Either the slug or tag were not found.
        eprint(f"Unable to lookup pre-release status for {slug}:{tag}")
        sys.exit(-3)

    if release.prerelease:
        # This is a prerelease: no DEPLOY_REGIONS.
        eprint(f"{tag} is a pre-release build.")
        print('export PACKER_DEPLOY_REGIONS=""')
        print('export PACKER_PRE_RELEASE="True"')
        sys.exit(0)
    else:
        # This is a regular release: pass DEPLOY_REGIONS through.
        eprint(f"{tag} is NOT a pre-release build.")
        print(f'export PACKER_DEPLOY_REGIONS="f{os.getenv("PACKER_DEPLOY_REGIONS")}"')
        print('export PACKER_PRE_RELEASE="False"')
        sys.exit(-1)


if __name__ == "__main__":
    main()
