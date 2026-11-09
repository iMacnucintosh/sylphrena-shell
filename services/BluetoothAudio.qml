pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Sylphrena.I18n

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

    function cardFor(address: string): var {
        return root.cards[String(address).toUpperCase()] ?? null;
    }

    function modeFor(address: string): string {
        const c = root.cardFor(address);
        if (!c)
            return "";
        if (root.autoswitch)
            return "auto";
        return c.profile.startsWith("headset-head-unit") ? "call" : "music";
    }

    function inCall(address: string): bool {
        return !!root.cardFor(address)?.profile.startsWith("headset-head-unit");
    }

    function profileLabel(profile: string): string {
        switch (profile) {
        case "a2dp-sink":
            return "AAC";
        case "a2dp-sink-sbc_xq":
            return "SBC-XQ";
        case "a2dp-sink-sbc":
            return "SBC";
        case "headset-head-unit":
            return "mSBC";
        case "headset-head-unit-cvsd":
            return "CVSD";
        default:
            return profile;
        }
    }

    // One-line state shown under the selector.
    function describe(address: string): string {
        const c = root.cardFor(address);
        if (!c)
            return "";
        const call = c.profile.startsWith("headset-head-unit");
        const codec = root.profileLabel(c.profile);
        return call ? Tr.tr("Now: call quality (%1), mic on").arg(codec) : Tr.tr("Now: high quality (%1), no mic").arg(codec);
    }

    function setMode(address: string, mode: string): void {
        const c = root.cardFor(address);
        if (!c || applyProc.running)
            return;
        // Auto goes back to the high quality profile; WirePlumber takes over from there.
        const profile = mode === "call" ? c.headset : c.a2dp;
        if (!profile)
            return;
        applyProc.command = ["sh", "-c", 'wpctl settings --save bluetooth.autoswitch-to-headset-profile "$1" && pactl set-card-profile "$2" "$3"', "sh", mode === "auto" ? "true" : "false", c.card, profile];
        applyProc.running = true;
    }

    function refresh(): void {
        listProc.running = true;
        settingProc.running = true;
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
