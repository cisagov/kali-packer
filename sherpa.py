#!/usr/bin/env python3
"""Helper script to work around stdout timout of Travis-CI.

If a long-running process does not output anything for 10 minutes
Travis will assume it has hung, and kill it.  Some tools (like Packer)
can easily go beyond this 10 minute mark without writing to stdout.
"""

from datetime import datetime, timedelta
import os
import subprocess  # nosec
import sys


def main():
    """Start a child process, output status, and monitor exit."""
    command = " ".join(sys.argv[1:])
    timeout = timedelta(minutes=int(os.getenv("SHERPA_TIMEOUT", 20)))
    now = datetime.utcnow()
    killtime = now + timeout
    print(f"Sherpaing: {command}")
    print(f"Sherpa will kill at {killtime}")

    child = subprocess.Popen(command, shell=True)  # nosec
    while now < killtime:
        try:
            sleep_time = min(60, (killtime - now).total_seconds())
            return_code = child.wait(sleep_time)
            if return_code is not None:
                # the child has exited before the timeout
                break
        except subprocess.TimeoutExpired:
            pass
        now = datetime.utcnow()
        print(f"Still running at {now}")
    else:
        print("Timeout reached... sherpa killing child.")
        child.kill()

    return_code = child.wait()
    print(f"Child has exited with: {return_code}")
    sys.exit(return_code)


if __name__ == "__main__":
    main()
