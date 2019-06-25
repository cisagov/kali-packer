#!/usr/bin/env pytest -vs
"""Version tests for packer skeleton project."""

import os

import pytest

TRAVIS_TAG = os.getenv("TRAVIS_TAG")
VERSION_FILE = "src/version.txt"


@pytest.mark.skipif(
    TRAVIS_TAG in [None, ""], reason="this is not a release (TRAVIS_TAG not set)"
)
def test_release_version():
    """Verify that release tag version agrees with the module version."""
    pkg_vars = {}
    with open(VERSION_FILE) as f:
        exec(f.read(), pkg_vars)  # nosec
    project_version = pkg_vars["__version__"]
    assert (
        TRAVIS_TAG == f"v{project_version}"
    ), "TRAVIS_TAG does not match the project version"
