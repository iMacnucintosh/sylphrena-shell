pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Sylphrena.Config
import Sylphrena.I18n
import qs.services

// Battery of the Razer Basilisk V4 Pro (2.4 GHz), read with `synapsex-cli battery`
// (~/Desarrollo/Projects/synapsex). Off = nothing is polled. Shown in the dashboard resources column
// in the slot of the storage ring.
Singleton {
    id: root

    readonly property bool enabled: GlobalConfig.addons.razerMouse.enabled
    readonly property int refreshMinutes: Math.max(1, GlobalConfig.addons.razerMouse.refreshMinutes)

    // The last reading worked (mouse found and answered)
    property bool available: false
    property int percent: 0
    property bool charging: false
    property string error: ""

    // What the dashboard ring shows
    readonly property bool shown: enabled && available
    readonly property bool low: available && !charging && percent <= 20

    // Level of the last low-battery notice (0 = none), so each threshold warns once per discharge
    property int lastWarnLevel: 0

    function setEnabled(on: bool): void {
        if (GlobalConfig.addons.razerMouse.enabled === on)
            return;
        GlobalConfig.addons.razerMouse.enabled = on;
    }

    function refresh(): void {
        if (!enabled || proc.running)
            return;
        proc.running = true;
    }

    function apply(text: string): void {
        const m = text.match(/Battery\s+(\d+)\s*%(\s*\(charging\))?/i);
        if (!m) {
            available = false;
            return;
        }
        percent = Math.max(0, Math.min(100, parseInt(m[1])));
        charging = !!m[2];
        available = true;
        error = "";
        checkLow();
    }

    function checkLow(): void {
        if (charging || percent > 25) {
            lastWarnLevel = 0;
            return;
        }
        const level = percent <= 10 ? 10 : percent <= 20 ? 20 : 0;
        if (level === 0 || (lastWarnLevel !== 0 && level >= lastWarnLevel))
            return;
        lastWarnLevel = level;
        Notifs.pushLocal({
            notificationId: "local:razer-mouse-battery",
            summary: Tr.tr("Mouse battery low"),
            body: Tr.tr("Razer Basilisk V4 Pro: %1 % left").arg(percent),
            appName: Tr.tr("Mouse"),
            appIcon: "input-mouse",
            expireTimeout: 8000,
            resident: false,
            actions: []
        });
    }

    onEnabledChanged: {
        if (enabled)
            refresh();
        else {
            available = false;
            lastWarnLevel = 0;
        }
    }

    Component.onCompleted: refresh()

    Timer {
        interval: root.refreshMinutes * 60 * 1000
        running: root.enabled
        repeat: true
        onTriggered: root.refresh()
    }

    // The CLI path comes in as $1 (never interpolated into the script)
    Process {
        id: proc

        command: ["sh", "-c", 'c="$1"; [ -z "$c" ] && c=$(command -v synapsex-cli); [ -z "$c" ] && c="$HOME/Desarrollo/Projects/synapsex/target/release/synapsex-cli"; exec timeout 25 "$c" battery </dev/null', "sh", GlobalConfig.addons.razerMouse.cliPath]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.apply(text)
        }
        stderr: StdioCollector {
            onStreamFinished: root.error = text.trim()
        }
        onExited: code => {
            if (code !== 0)
                root.available = false;
        }
    }
}
