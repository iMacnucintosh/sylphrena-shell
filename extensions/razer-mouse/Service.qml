pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils
import Sylphrena.I18n
import qs.services

// Service of the Razer mouse extension: battery of the Razer Basilisk V4 Pro (2.4 GHz), read with
// `synapsex-cli battery` (~/Desarrollo/Projects/synapsex). It exists only while the extension is
// enabled. The dashboard shows it through the `ring` property, in the slot of the storage ring.
Scope {
    id: root

    // Injected by the base (services/Extensions.qml)
    required property var ext

    // Settings (ext.config): `cliPath` ("" = look it up) and `refreshMinutes`
    readonly property string cliPath: root.ext.config.get("cliPath", "")
    readonly property int refreshMinutes: Math.max(1, root.ext.config.get("refreshMinutes", 5))

    // There is a value to show: a fresh reading, or the last one saved (the CLI takes a few seconds,
    // and the mouse may be asleep or away)
    property bool available: false
    // The value is the saved one; no reading has succeeded yet in this session
    property bool stale: false
    property int percent: 0
    property bool charging: false
    property string error: ""

    readonly property bool low: available && !charging && percent <= 20

    // Resource ring contract (manifest `contributes.resourceRing`): the base draws a ring with this
    // when `shown`. `value` is 0..1, `warn` paints it as an error, `badge` is an icon in the corner.
    readonly property var ring: ({
            shown: available,
            value: percent / 100,
            icon: "mouse",
            warn: low,
            badge: charging ? "bolt" : ""
        })
    // One line for the Nexus list
    readonly property string statusText: available ? (charging ? Tr.tr("Basilisk V4 Pro · %1 % · charging") : Tr.tr("Basilisk V4 Pro · %1 %")).arg(percent) : Tr.tr("Mouse not found — needs synapsex-cli")

    // Level of the last low-battery notice (0 = none), so each threshold warns once per discharge
    property int lastWarnLevel: 0

    function refresh(): void {
        if (proc.running)
            return;
        proc.running = true;
    }

    function apply(text: string): void {
        const m = text.match(/Battery\s+(\d+)\s*%(\s*\(charging\))?/i);
        if (!m)
            return; // keep the last known value
        percent = Math.max(0, Math.min(100, parseInt(m[1])));
        charging = !!m[2];
        available = true;
        stale = false;
        error = "";
        saveTimer.restart();
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

    Component.onCompleted: refresh()

    Timer {
        interval: root.refreshMinutes * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    // The CLI path comes in as $1 (never interpolated into the script)
    Process {
        id: proc

        command: ["sh", "-c", 'c="$1"; [ -z "$c" ] && c=$(command -v synapsex-cli); [ -z "$c" ] && c="$HOME/Desarrollo/Projects/synapsex/target/release/synapsex-cli"; exec timeout 25 "$c" battery </dev/null', "sh", root.cliPath]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.apply(text)
        }
        stderr: StdioCollector {
            onStreamFinished: root.error = text.trim()
        }
    }

    // Last value read, kept across restarts so the ring is there from the start
    Timer {
        id: saveTimer

        interval: 500
        onTriggered: storage.setText(JSON.stringify({
                percent: root.percent,
                charging: root.charging,
                at: Date.now()
            }))
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.state}/razer-mouse.json`
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (!root.available && typeof d.percent === "number") {
                    root.percent = Math.max(0, Math.min(100, Math.round(d.percent)));
                    root.charging = !!d.charging;
                    root.available = true;
                    root.stale = true;
                }
            } catch (e) {
                console.warn(`Unable to parse razer-mouse.json: ${e}`);
            }
        }
    }
}
