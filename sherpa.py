#!/usr/bin/env python3
"""Helper script to work around stdout timout of Travis-CI.

If a long-running process does not output anything for 10 minutes
Travis will assume it has hung, and kill it.  Some tools (like Packer)
can easily go beyond this 10 minute mark without writing to stdout.

By default it will allow the child to run up to 20 minutes.  This value
can be changed by setting the SHERPA_TIMEOUT environment variable.
"""

from datetime import datetime, timedelta
import os
import subprocess  # nosec
import sys


class bcolor:
    """Define ANSI colors."""

    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


def sherprint(message, color=bcolor.OKGREEN):
    """Print a sherpa message."""
    print(f"{bcolor.HEADER}Sherpa ❱ {color}{message}{bcolor.ENDC}", flush=True)


def main():
    """Start a child process, output status, and monitor exit."""
    command = " ".join(sys.argv[1:])
    timeout = timedelta(minutes=int(os.getenv("SHERPA_TIMEOUT", 20)))
    now = datetime.utcnow()
    killtime = now + timeout
    sherprint(f"{command}")
    sherprint(f"max runtime {timeout}")
    sherprint(f"will kill at {killtime}")

    child = subprocess.Popen(command, shell=True)  # nosec
    while now < killtime:
        sherprint(f"{(killtime - now)} remaining", color=bcolor.WARNING)
        try:
            sleep_time = min(60, (killtime - now).total_seconds())
            return_code = child.wait(sleep_time)
            if return_code is not None:
                # the child has exited before the timeout
                break
        except subprocess.TimeoutExpired:
            pass
        now = datetime.utcnow()
    else:
        sherprint("Timeout reached... killing child.", color=bcolor.FAIL)
        child.kill()

    return_code = child.wait()
    if return_code == 0:
        sherprint(f"Child has exited with: {return_code}")
    else:
        sherprint(f"Child has exited with: {return_code}", color=bcolor.FAIL)

    sys.exit(return_code)


if __name__ == "__main__":
    main()
