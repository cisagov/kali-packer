#!/usr/bin/env python
"""Script to output shell commands needed to update the evironment.

This script uses the GitHub API and the TRAVIS_REPO_SLUG and TRAVIS_TAG environment
variables to determine if the current build is a pre-release.  It will then output
shell commands for evaulation based on the pre-release status.

When running in a Travis CI it is possible that the GitHub API call will be rate
limited by the shared IP of all Travis users.  Setting the GITHUB_ACCESS_TOKEN
will cause this script to be limited by the token owner instead.

See: https://developer.github.com/v3/#rate-limiting

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
    # if we have a Github access token use it, otherwise we may be rate limited
    # by all the other Travis users coming from the same IP.
    access_token = os.getenv("GITHUB_ACCESS_TOKEN")
    if access_token:
        g = Github(access_token)
    else:
        g = Github()

    slug = os.getenv("TRAVIS_REPO_SLUG")
    if not slug:
        eprint("TRAVIS_REPO_SLUG not set")
        sys.exit(-1)

    tag = os.getenv("TRAVIS_TAG")
    if not tag:
        eprint("TRAVIS_TAG not set")
        sys.exit(-1)

    try:
        repo = g.get_repo(slug)
        release = repo.get_release(tag)
    except UnknownObjectException:
        # Either the slug or tag were not found.
        eprint(f"Unable to lookup pre-release status for {slug}:{tag}")
        sys.exit(-1)

    if release.prerelease:
        # This is a prerelease: no PACKER_DEPLOY_REGIONS.
        eprint(f"{tag} is a pre-release build.")
        print('export PACKER_DEPLOY_REGIONS=""')
        print('export PACKER_PRE_RELEASE="True"')
    else:
        # This is a regular release: do not modify PACKER_DEPLOY_REGIONS.
        eprint(f"{tag} is NOT a pre-release build.")
        print('export PACKER_PRE_RELEASE="False"')

    sys.exit(0)


if __name__ == "__main__":
    main()
