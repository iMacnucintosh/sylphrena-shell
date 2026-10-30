#!/usr/bin/env python3
"""SUDO_ASKPASS helper: fetch the in-memory password from the helper socket."""
from __future__ import annotations

import os
import socket
import sys


def main() -> None:
    path = os.environ.get("SYLPHRENA_SUDO_ASKPASS_SOCK") or os.environ.get("SYLPHRENA_SUDO_ASKPASS_SOCK", "")
    if not path:
        sys.exit(1)
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(path)
    data = sock.recv(4096)
    sock.close()
    if not data:
        sys.exit(1)
    sys.stdout.buffer.write(data)


if __name__ == "__main__":
    main()
