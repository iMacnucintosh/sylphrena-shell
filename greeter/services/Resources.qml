pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// CPU/memory/disk/temperature, read straight from procfs + sysfs (no
// Caelestia plugin, no extra dependencies).
Singleton {
    id: root

    property real cpu
    property real mem
    property real disk
    property int temp

    property real prevIdle: -1
    property real prevTotal: -1

    function parseStat(text: string): void {
        const line = text.split("\n").find(l => l.startsWith("cpu "));
        if (!line)
            return;
        const fields = line.trim().split(/\s+/).slice(1).map(Number);
        const idle = fields[3] + fields[4];
        const total = fields.reduce((a, b) => a + b, 0);
        if (root.prevTotal >= 0 && total > root.prevTotal) {
            const dTotal = total - root.prevTotal;
            const dIdle = idle - root.prevIdle;
            root.cpu = Math.max(0, Math.min(1, (dTotal - dIdle) / dTotal));
        }
        root.prevTotal = total;
        root.prevIdle = idle;
    }

    function parseMeminfo(text: string): void {
        const total = Number(text.match(/^MemTotal:\s+(\d+)/m)?.[1] ?? 0);
        const available = Number(text.match(/^MemAvailable:\s+(\d+)/m)?.[1] ?? 0);
        if (total > 0)
            root.mem = Math.max(0, Math.min(1, 1 - available / total));
    }

    function parseDf(text: string): void {
        const value = text.match(/(\d+)%/);
        if (value)
            root.disk = Number(value[1]) / 100;
    }

    function parseTemp(text: string): void {
        const value = Number(text.trim());
        if (Number.isFinite(value) && value > 0)
            root.temp = Math.round(value / 1000);
    }

    FileView {
        id: statFile

        path: "/proc/stat"

        onLoaded: root.parseStat(text())
    }

    FileView {
        id: meminfoFile

        path: "/proc/meminfo"

        onLoaded: root.parseMeminfo(text())
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            meminfoFile.reload();
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            dfProc.running = false;
            dfProc.running = true;
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            tempProc.running = false;
            tempProc.running = true;
        }
    }

    Process {
        id: dfProc

        command: ["df", "--output=pcent", "/"]

        stdout: StdioCollector {
            onStreamFinished: root.parseDf(text)
        }
    }

    Process {
        id: tempProc

        command: [
            "sh", "-c",
            `for d in /sys/class/hwmon/hwmon*; do
  [ -r "$d/name" ] || continue
  case $(cat "$d/name") in
    k10temp|coretemp|zenpower|cpu_thermal|acpitz) cat "$d/temp1_input" 2>/dev/null && exit 0;;
  esac
done`
        ]

        stdout: StdioCollector {
            onStreamFinished: root.parseTemp(text)
        }
    }
}
