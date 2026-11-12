pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

// Audio profile of connected Bluetooth headsets (music = A2DP, calls = HFP/HSP).
//
// Three user-facing modes:
//   music — A2DP fixed, no mic
//   call  — headset profile fixed, mic always present (apps like Teams only list the
//           mic if it exists when the call starts)
//   auto  — WirePlumber switches to the headset profile when an app records
// "auto" is WirePlumber's global `bluetooth.autoswitch-to-headset-profile` setting; the
// other two turn it off and pin the profile on the card.
Singleton {
    id: root

    // upper-case MAC -> { card, profile, a2dp, headset } (best available profile names)
    property var cards: ({})
    property bool autoswitch: true

    // AirPods battery (BlueZ does not publish it): upper-case MAC -> { left, right, case } in %
    property var batteries: ({})
    property real lastBatteryPoll: 0
    readonly property bool pollingBattery: batteryProc.running

    function cardFor(address: string): var {
        return root.cards[String(address).toUpperCase()] ?? null;
    }

    // Lowest bud level (0..1) for headsets whose battery comes from the accessory channel, or -1
    function batteryFor(address: string): real {
        const b = root.batteries[String(address).toUpperCase()];
        if (!b)
            return -1;
        const buds = [b.left, b.right].filter(v => v !== null && v !== undefined);
        return buds.length ? Math.min(...buds) / 100 : -1;
    }

    // Per-component levels (0..1, -1 = not reported) or null when there is no accessory-channel data
    function podsFor(address: string): var {
        const b = root.batteries[String(address).toUpperCase()];
        if (!b)
            return null;
        const f = v => v === null || v === undefined ? -1 : v / 100;
        return {
            left: f(b.left),
            right: f(b.right),
            "case": f(b.case)
        };
    }

    function pollBattery(force: bool): void {
        if (batteryProc.running || (!force && Date.now() - root.lastBatteryPoll < 30000))
            return;
        const dev = Bluetooth.devices.values.find(d => d.connected && /airpods/i.test(d.name));
        if (!dev) {
            if (Object.keys(root.batteries).length)
                root.batteries = ({});
            return;
        }
        root.lastBatteryPoll = Date.now();
        batteryProc.address = dev.address.toUpperCase();
        batteryProc.command = ["python3", "-I", `${Quickshell.shellDir}/scripts/airpods-battery.py`, batteryProc.address];
        batteryProc.running = true;
    }

    function modeFor(address: string): string {
        const c = root.cardFor(address);
        if (!c)
            return "";
        if (root.autoswitch)
            return "auto";
        return c.profile.startsWith("headset-head-unit") ? "call" : "music";
    }

    // Output node of the headset in its current profile (A2DP and HFP have separate sinks).
    function sinkFor(address: string): var {
        const key = `bluez_output.${String(address).replace(/:/g, "_")}`;
        return Audio.sinks.find(n => n.name.startsWith(key)) ?? null;
    }

    function codecLabel(profile: string): string {
        switch (profile) {
        case "a2dp-sink":
            return "AAC";
        case "a2dp-sink-sbc_xq":
            return "SBC-XQ";
        case "a2dp-sink-sbc":
            return "SBC";
        case "headset-head-unit":
            return "HFP";
        case "headset-head-unit-cvsd":
            return "CVSD";
        default:
            return profile;
        }
    }

    // A2DP (music) profiles the headset offers, best first
    function a2dpOptions(address: string): var {
        return root.cardFor(address)?.a2dpAll ?? [];
    }

    // Pick a specific profile (e.g. the music codec) without touching the auto-switch setting
    function setProfile(address: string, profile: string): void {
        const c = root.cardFor(address);
        if (!c || applyProc.running)
            return;
        applyProc.command = ["pactl", "set-card-profile", c.card, profile];
        applyProc.running = true;
    }

    function setMode(address: string, mode: string): void {
        const c = root.cardFor(address);
        if (!c || applyProc.running)
            return;
        // Auto goes back to the high quality profile; WirePlumber takes over from there.
        const profile = mode === "call" ? c.headset : c.a2dp;
        if (!profile)
            return;
        applyProc.command = ["sh", "-c", 'wpctl settings --save bluetooth.autoswitch-to-headset-profile "$1" && pactl set-card-profile "$2" "$3"; sleep 1; for s in $(pactl list short sinks | cut -f2 | grep "^bluez_output\\.$4\\."); do pactl set-sink-mute "$s" 0; done', "sh", mode === "auto" ? "true" : "false", c.card, profile, String(address).replace(/:/g, "_")];
        applyProc.running = true;
    }

    function refresh(): void {
        listProc.running = true;
        settingProc.running = true;
        root.pollBattery(false);
    }

    function best(profiles: var, order: list<string>): string {
        for (const name of order) {
            const p = profiles[name];
            if (p && p.available !== "no")
                return name;
        }
        return "";
    }

    function parse(text: string): void {
        let data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            return;
        }
        const out = {};
        for (const c of data) {
            if (!c.name?.startsWith("bluez_card."))
                continue;
            const address = String(c.properties?.["api.bluez5.address"] ?? "").toUpperCase();
            if (!address)
                continue;
            out[address] = {
                card: c.name,
                profile: c.active_profile ?? "",
                a2dp: root.best(c.profiles, ["a2dp-sink", "a2dp-sink-sbc_xq", "a2dp-sink-sbc"]),
                a2dpAll: ["a2dp-sink", "a2dp-sink-sbc_xq", "a2dp-sink-sbc"].filter(n => c.profiles[n] && c.profiles[n].available !== "no"),
                headset: root.best(c.profiles, ["headset-head-unit", "headset-head-unit-cvsd"])
            };
        }
        root.cards = out;
    }

    Component.onCompleted: root.refresh()

    Process {
        id: listProc

        command: ["pactl", "-f", "json", "list", "cards"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Process {
        id: settingProc

        command: ["wpctl", "settings", "bluetooth.autoswitch-to-headset-profile"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/Value:\s*(true|false)/);
                if (m)
                    root.autoswitch = m[1] === "true";
            }
        }
    }

    Process {
        id: batteryProc

        property string address

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const b = JSON.parse(text);
                    const all = Object.assign({}, root.batteries);
                    all[batteryProc.address] = b;
                    root.batteries = all;
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 120000
        repeat: true
        running: true
        onTriggered: root.pollBattery(true)
    }

    Process {
        id: applyProc

        onExited: root.refresh()
    }

    // Card changes (profile switches, devices connecting) → re-read, debounced.
    Process {
        running: true
        command: ["pactl", "subscribe"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes(" card "))
                    debounce.restart();
            }
        }
    }

    Timer {
        id: debounce

        interval: 300
        onTriggered: root.refresh()
    }
}
