#!/usr/bin/env python3
"""SUDO_ASKPASS helper: fetch the in-memory password from the helper socket."""
from __future__ import annotations

import os
import socket
import sys


def main() -> None:
    path = os.environ.get("SYLPHRENA_SUDO_ASKPASS_SOCK", "")
    if not path:
        sys.exit(1)
    data = b""
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.connect(path)
        while chunk := sock.recv(4096):     # until the helper closes: one recv could return part of it
            data += chunk
    if not data:
        sys.exit(1)
    sys.stdout.buffer.write(data)


if __name__ == "__main__":
    main()
