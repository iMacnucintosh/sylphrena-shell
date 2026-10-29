pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// The greeter only needs the few facts caelestiafetch shows on the lock.
Singleton {
    id: root

    property string osName
    property string osPrettyName
    property string uptime

    readonly property string wm: "Hyprland"
    readonly property string user: Theme.displayName

    function parseOsRelease(text: string): void {
        const values = {};
        for (const line of text.split("\n")) {
            const match = line.match(/^([A-Z_]+)=(.*)$/);
            if (!match)
                continue;
            values[match[1]] = match[2].replace(/^"|"$/g, "");
        }
        root.osName = values.NAME ?? "";
        root.osPrettyName = values.PRETTY_NAME ?? values.NAME ?? "";
    }

    function parseUptime(text: string): void {
        const seconds = Math.floor(parseFloat(text.trim()));
        if (!Number.isFinite(seconds))
            return;
        const days = Math.floor(seconds / 86400);
        const hours = Math.floor((seconds % 86400) / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        root.uptime = days ? `${days}d ${hours}h` : hours ? `${hours}h ${minutes}m` : `${minutes}m`;
    }

    FileView {
        path: "/etc/os-release"

        onLoaded: root.parseOsRelease(text())
    }

    FileView {
        id: uptimeFile

        path: "/proc/uptime"

        onLoaded: root.parseUptime(text())
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: uptimeFile.reload()
    }
}
