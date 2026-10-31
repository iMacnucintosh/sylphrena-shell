pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import M3Shapes
import Sylphrena
import Sylphrena.Config
import Sylphrena.I18n
import Sylphrena.Services
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    property string quickshellVersion
    property string cliVersion
    property string hyprlandVersion
    property string primaryMonitorValue
    property string primaryMonitorSub
    // pacman -Qn (repos) / -Qm (foreign≈AUR) / flatpak apps
    property int archPackageCount: -1
    property int aurPackageCount: -1
    property int flatpakPackageCount: -1

    readonly property bool hasGpu: Gpu.type !== GpuType.None && !!Gpu.name
    readonly property var primaryDisk: Storage.primaryDisk

    function formatCount(n: int): string {
        return n >= 0 ? n.toString() : "…";
    }

    // MemTotal is usable RAM (firmware steals ~1 GiB). Snap to the nearest
    // common DIMM capacity so About shows what is installed (32 GiB, not 31).
    function formatInstalledMemory(totalKib: real): string {
        if (!(totalKib > 0))
            return "…";
        const gib = totalKib / (1024 * 1024);
        const standards = [2, 4, 6, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 256, 512];
        let best = Math.round(gib);
        let bestDiff = Infinity;
        for (let i = 0; i < standards.length; i++) {
            const d = Math.abs(gib - standards[i]);
            if (d < bestDiff) {
                bestDiff = d;
                best = standards[i];
            }
        }
        if (bestDiff / best > 0.1)
            return Units.formatBytes(totalKib * 1024);
        const binary = Number(GlobalConfig.services.dataUnits) === DataUnit.Binary;
        return Units.withDataUnit(best, binary ? "GiB" : "GB");
    }

    title: Tr.tr("System information")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ServiceRef {
            service: Cpu
        }

        ServiceRef {
            service: Gpu
        }

        ServiceRef {
            service: Memory
        }

        ServiceRef {
            service: Storage
        }

        Process {
            running: true
            command: ["hyprctl", "-j", "version"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        root.hyprlandVersion = JSON.parse(text).version || "";
                    } catch (e) {
                        root.hyprlandVersion = "";
                    }
                }
            }
        }

        // Focused output first, else the first connected monitor.
        Process {
            running: true
            command: ["hyprctl", "monitors", "-j"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const list = JSON.parse(text || "[]");
                        if (!Array.isArray(list) || list.length === 0) {
                            root.primaryMonitorValue = "";
                            root.primaryMonitorSub = "";
                            return;
                        }
                        const m = list.find(x => x && x.focused && !x.disabled) || list.find(x => x && !x.disabled) || list[0];
                        const hz = Math.round(Number(m.refreshRate) || 0);
                        root.primaryMonitorValue = hz > 0 ? `${m.width}×${m.height} @ ${hz} Hz` : `${m.width}×${m.height}`;
                        root.primaryMonitorSub = m.description || m.model || m.name || "";
                    } catch (e) {
                        root.primaryMonitorValue = "";
                        root.primaryMonitorSub = "";
                    }
                }
            }
        }

        // Quickshell runtime version — "Quickshell 0.3.2 (revision …)"
        Process {
            running: true
            command: ["quickshell", "--version"]
            stdout: StdioCollector {
                onStreamFinished: root.quickshellVersion = text.trim().split(" ")[1] ?? ""
            }
        }

        // User-local pip/editable install exposes importlib metadata; pacman
        // package (if present) is the fallback via sylph -v.
        Process {
            running: true
            command: ["sh", "-c", "python3 -c \"import importlib.metadata as m; print(m.version('sylphrena'))\" 2>/dev/null || sylph -v 2>/dev/null | sed -n 's/^[[:space:]]*sylphrena-cli[[:space:]]\\+\\([0-9][^[:space:]]*\\).*/\\1/p'"]
            stdout: StdioCollector {
                onStreamFinished: root.cliVersion = text.trim().split("\n")[0] ?? ""
            }
        }

        // Three lines: native Arch, foreign (AUR), Flatpak apps — same sources as Updates.
        Process {
            running: true
            command: ["sh", "-c", "printf '%s\\n' \"$(pacman -Qnq 2>/dev/null | wc -l)\" \"$(pacman -Qmq 2>/dev/null | wc -l)\" \"$(flatpak list --app --columns=application 2>/dev/null | wc -l)\""]
            stdout: StdioCollector {
                onStreamFinished: {
                    const lines = text.trim().split("\n");
                    const parse = i => {
                        const n = parseInt(lines[i] ?? "", 10);
                        return Number.isFinite(n) ? n : -1;
                    };
                    root.archPackageCount = parse(0);
                    root.aurPackageCount = parse(1);
                    root.flatpakPackageCount = parse(2);
                }
            }
        }

        // Hero
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: hero.implicitHeight + Tokens.padding.extraLarge * 2

            ColumnLayout {
                id: hero

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                spacing: Tokens.spacing.small

                // Orb + Arch Gem badge (same motif as dashboard User.qml;
                // tertiary so it pops against the primary orb, not the accent).
                Item {
                    id: orbWrap

                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight
                    implicitWidth: sylph.implicitWidth
                    implicitHeight: sylph.implicitHeight

                    SylphOrb {
                        id: sylph

                        anchors.centerIn: parent
                        orbSize: 96
                    }

                    MaterialShape {
                        id: archBadge

                        readonly property int badgeSize: Tokens.padding.extraLarge * 2 + Tokens.padding.small

                        // Top-left of the cookie, overlapping like the dashboard logo.
                        x: (parent.width - sylph.orbSize) / 3 - Tokens.padding.label
                        y: (parent.height - sylph.orbSize) / 3 - Tokens.padding.large
                        z: 2
                        implicitSize: badgeSize
                        shape: MaterialShape.Gem
                        color: Colours.palette.m3tertiaryContainer

                        Behavior on color {
                            CAnim {}
                        }

                        ColouredIcon {
                            anchors.centerIn: parent
                            source: SysInfo.osLogo
                            implicitSize: Math.round(archBadge.badgeSize * 0.55)
                            colour: Colours.palette.m3onTertiaryContainer
                        }
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.small
                    text: "Sylphrena"
                    font: Tokens.font.headline.builders.large.width(110).build()
                }

                StyledRect {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.extraSmall
                    implicitWidth: versionChip.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: versionChip.implicitHeight + Tokens.padding.extraSmall
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3secondaryContainer

                    StyledText {
                        id: versionChip

                        anchors.centerIn: parent
                        text: CUtils.version ? `v${CUtils.version}` : "…"
                        color: Colours.palette.m3onSecondaryContainer
                        font: Tokens.font.label.medium
                    }
                }
            }
        }

        // System
        SectionHeader {
            text: Tr.tr("System")
        }

        InfoRow {
            first: true
            icon: "computer"
            label: Tr.tr("Hostname")
            value: SysInfo.hostname
        }

        InfoRow {
            icon: "deployed_code"
            label: Tr.tr("Distro")
            value: SysInfo.osPrettyName || SysInfo.osName
        }

        InfoRow {
            icon: "terminal"
            label: Tr.tr("Kernel")
            value: SysInfo.kernel
        }

        InfoRow {
            icon: "developer_board"
            // TRANSLATORS: BIOS or UEFI firmware version from DMI
            label: Tr.tr("BIOS version")
            value: SysInfo.firmware || "—"
        }

        InfoRow {
            last: true
            icon: "clock_arrow_up"
            label: Tr.tr("Uptime")
            value: SysInfo.uptime || "…"
        }

        // Packages — icons match Updates (settings / 👽 / deployed_code)
        SectionHeader {
            text: Tr.tr("Packages")
        }

        InfoRow {
            first: true
            icon: "settings"
            label: Tr.tr("Arch repositories")
            value: root.formatCount(root.archPackageCount)
        }

        InfoRow {
            label: Tr.tr("AUR")
            value: root.formatCount(root.aurPackageCount)
            leadingComponent: Component {
                StyledText {
                    text: "👽"
                    font.family: "Noto Color Emoji"
                    font.pixelSize: Math.round(Tokens.font.icon.small.pointSize * 1.35)
                }
            }
        }

        InfoRow {
            last: true
            icon: "deployed_code"
            label: Tr.tr("Flatpak")
            value: root.formatCount(root.flatpakPackageCount)
        }

        // Hardware
        SectionHeader {
            text: Tr.tr("Hardware")
        }

        InfoRow {
            first: true
            icon: "memory"
            label: Tr.tr("CPU")
            value: Cpu.name || "…"
        }

        Loader {
            Layout.fillWidth: true
            active: root.hasGpu
            visible: active
            asynchronous: true

            sourceComponent: InfoRow {
                icon: "videogame_asset"
                label: Tr.tr("GPU")
                value: Gpu.name
            }
        }

        InfoRow {
            icon: "memory_alt"
            label: Tr.tr("Memory")
            value: root.formatInstalledMemory(Memory.total)
        }

        InfoRow {
            icon: "monitor"
            // TRANSLATORS: focused / primary Hyprland output
            label: Tr.tr("Primary monitor")
            value: root.primaryMonitorValue || "…"
            subtext: root.primaryMonitorSub
        }

        // Storage with free space + usage bar
        ConnectedRect {
            id: storageRow

            Layout.fillWidth: true
            last: true
            implicitHeight: storageCol.implicitHeight + Tokens.padding.medium * 2

            ColumnLayout {
                id: storageCol

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: "hard_drive"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("Storage")
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: !!root.primaryDisk
                            text: root.primaryDisk ? Units.formatKibUsage(root.primaryDisk.used, root.primaryDisk.total) : ""
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    StyledText {
                        Layout.maximumWidth: storageRow.width / 2
                        horizontalAlignment: Text.AlignRight
                        text: root.primaryDisk ? Tr.tr("%1 free").arg(Units.formatBytes(root.primaryDisk.free * 1024)) : Tr.tr("No disks detected")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }
                }

                StyledProgressBar {
                    Layout.fillWidth: true
                    Layout.leftMargin: Tokens.spacing.extraLarge + Tokens.spacing.medium
                    implicitHeight: Tokens.rounding.extraSmall
                    visible: !!root.primaryDisk
                    value: root.primaryDisk?.perc ?? 0
                    fgColour: Colours.palette.m3primary
                    bgColour: Colours.palette.m3surfaceContainerHighest
                }
            }
        }

        // Software stack
        SectionHeader {
            text: Tr.tr("Software")
        }

        InfoRow {
            first: true
            icon: "window"
            label: "Hyprland"
            value: root.hyprlandVersion || "…"
        }

        InfoRow {
            icon: "auto_awesome"
            label: Tr.trCtx("Shell", "the sylphrena shell itself, not a unix shell")
            value: CUtils.version || "…"
        }

        InfoRow {
            icon: "terminal"
            label: Tr.trCtx("CLI", "the sylphrena command line tool")
            value: root.cliVersion || "…"
        }

        InfoRow {
            icon: "widgets"
            label: "Quickshell"
            value: root.quickshellVersion || "…"
        }

        InfoRow {
            last: true
            icon: "tune"
            label: "Qt"
            value: CUtils.qtVersion || "…"
        }
    }
}
