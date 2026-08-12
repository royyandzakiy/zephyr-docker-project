"""Global pytest configuration and fixtures."""
import pytest
import subprocess
from pathlib import Path


@pytest.fixture
def project_root():
    """Return the project root directory."""
    return Path(__file__).parent.resolve()


@pytest.fixture
def run_command():
    """Helper to run shell commands and capture output."""
    def _run(cmd, cwd=None, check=True):
        result = subprocess.run(
            cmd,
            shell=True,
            cwd=cwd,
            capture_output=True,
            text=True
        )
        if check and result.returncode != 0:
            pytest.fail(f"Command failed: {cmd}\n{result.stderr}")
        return result
    return _run
