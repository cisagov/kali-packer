#!/usr/bin/env pytest -vs
"""Version tests for packer skeleton project."""

# Standard Python Libraries
import os

# Third-Party Libraries
import pytest

GITHUB_RELEASE_TAG = os.getenv("GITHUB_RELEASE_TAG")
VERSION_FILE = "src/version.txt"


@pytest.mark.skipif(
    GITHUB_RELEASE_TAG in [None, ""],
    reason="this is not a release (GITHUB_RELEASE_TAG not set)",
)
def test_release_version():
    """Verify that release tag version agrees with the module version."""
    pkg_vars = {}
    with open(VERSION_FILE) as f:
        exec(f.read(), pkg_vars)  # nosec
    project_version = pkg_vars["__version__"]
    assert (
        GITHUB_RELEASE_TAG == f"v{project_version}"
    ), "GITHUB_RELEASE_TAG does not match the project version"
