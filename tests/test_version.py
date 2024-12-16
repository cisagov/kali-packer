"""Version tests for packer skeleton project."""

# Standard Python Libraries
import os

# Third-Party Libraries
import pytest

GITHUB_RELEASE_TAG = os.getenv("GITHUB_RELEASE_TAG")
VERSION_FILE = "version.txt"


@pytest.mark.skipif(
    GITHUB_RELEASE_TAG in [None, ""],
    reason="this is not a release (GITHUB_RELEASE_TAG not set)",
)
def test_release_version():
    """Verify that release tag version agrees with the module version."""
    with open(VERSION_FILE) as f:
        project_version = f.read().strip()
    assert (
        GITHUB_RELEASE_TAG == f"v{project_version}"
    ), "GITHUB_RELEASE_TAG does not match the project version"
