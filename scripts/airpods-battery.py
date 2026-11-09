#!/usr/bin/env python3
"""Battery of connected AirPods, read over Apple's accessory channel (L2CAP PSM 0x1001).

BlueZ does not publish it, so the shell asks the earbuds directly: connect, handshake,
subscribe to notifications, read the battery packet, disconnect. Read-only and short
(~2 s). Prints one JSON line on stdout:

    {"left": 81, "right": null, "case": 83}

Values are percentages; null = not reported (bud in the case, unknown). Exit 1 and an
empty stdout on failure. Usage: airpods-battery.py <MAC>
"""
import json
import socket
import sys
import time

PSM = 0x1001
HANDSHAKE = bytes.fromhex("00000400010002000000000000000000")
SUBSCRIBE = bytes.fromhex("040004000F00FFFFFFFF")
BATTERY_HEADER = bytes.fromhex("040004000400")
# Component ids in the battery packet: 2 = right bud, 4 = left bud, 8 = case
COMPONENTS = {2: "right", 4: "left", 8: "case"}


def parse(packet: bytes):
    if packet[:6] != BATTERY_HEADER or len(packet) < 7:
        return None
    out = {}
    for i in range(packet[6]):
        entry = packet[7 + i * 5 : 12 + i * 5]
        if len(entry) < 5 or entry[0] not in COMPONENTS:
            continue
        level = entry[2]
        # status 4 = not available (e.g. case while the buds are out); levels above 100 are "unknown"
        out[COMPONENTS[entry[0]]] = level if entry[3] != 4 and level <= 100 else None
    return out


def main() -> int:
    if len(sys.argv) != 2:
        return 2
    sock = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_SEQPACKET, socket.BTPROTO_L2CAP)
    sock.settimeout(4)
    try:
        sock.connect((sys.argv[1], PSM))
        sock.send(HANDSHAKE)
        time.sleep(0.3)
        sock.send(SUBSCRIBE)
        deadline = time.time() + 3
        while time.time() < deadline:
            try:
                data = sock.recv(1024)
            except socket.timeout:
                break
            result = parse(data)
            if result is not None:
                print(json.dumps({k: result.get(k) for k in ("left", "right", "case")}))
                return 0
    except OSError:
        pass
    finally:
        sock.close()
    return 1


if __name__ == "__main__":
    sys.exit(main())
