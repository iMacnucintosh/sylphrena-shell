#!/usr/bin/env python3
"""Hold a sudo password in RAM and serve it over a unix socket.

The password is read once from stdin (one line) and never written to disk.
SUDO_ASKPASS clients connect to the socket path given as argv[1].
"""
from __future__ import annotations

import os
import signal
import socket
import struct
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
    # Private from the moment it exists (bind, then chmod, left a window with the umask's mode)
    old_umask = os.umask(0o077)
    try:
        sock.bind(path)
    finally:
        os.umask(old_umask)
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
            # Only this user's processes (the socket may live in /tmp when there is no XDG_RUNTIME_DIR)
            uid = struct.unpack("3i", conn.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, struct.calcsize("3i")))[1]
            if uid == os.getuid():
                conn.sendall(pw)
        finally:
            conn.close()


if __name__ == "__main__":
    main()
