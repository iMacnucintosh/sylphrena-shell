#!/usr/bin/env python3
"""Hold a sudo password in RAM and serve it over a unix socket.

The password is read once from stdin (one line) and never written to disk.
SUDO_ASKPASS clients connect to the socket path given as argv[1].
"""
from __future__ import annotations

import os
import signal
import socket
import sys


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(2)
    path = sys.argv[1]
    pw = sys.stdin.buffer.readline()
    if not pw:
        sys.exit(2)
    if not pw.endswith(b"\n"):
        pw += b"\n"

    try:
        os.unlink(path)
    except FileNotFoundError:
        pass

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.bind(path)
    os.chmod(path, 0o600)
    sock.listen(8)

    def stop(*_args: object) -> None:
        try:
            os.unlink(path)
        except FileNotFoundError:
            pass
        os._exit(0)

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    while True:
        conn, _ = sock.accept()
        try:
            conn.sendall(pw)
        finally:
            conn.close()


if __name__ == "__main__":
    main()
