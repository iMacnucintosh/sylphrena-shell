pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Bluetooth
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property PopoutState popouts

    width: Math.max(480, Tokens.sizes.bar.networkWidth)
    spacing: Tokens.spacing.small
    // Hairline inset past the leading device icon
    readonly property real deviceTextInset: Tokens.font.icon.small.pointSize + Tokens.spacing.small + Tokens.spacing.extraSmall

    StyledText {
        Layout.topMargin: Tokens.padding.medium
        Layout.rightMargin: Tokens.padding.extraSmall
        text: Tr.tr("Bluetooth")
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    Toggle {
        label: Tr.trCtx("Enabled", "toggle label")
        checked: Bluetooth.defaultAdapter?.enabled ?? false
        toggle.onToggled: {
            const adapter = Bluetooth.defaultAdapter;
            if (adapter)
                adapter.enabled = checked;
        }
    }

    Toggle {
        label: Tr.trCtx("Discovering", "bluetooth adapter state")
        checked: Bluetooth.defaultAdapter?.discovering ?? false
        toggle.onToggled: {
            const adapter = Bluetooth.defaultAdapter;
            if (adapter)
                adapter.discovering = checked;
        }
    }

    StyledText {
        Layout.topMargin: Tokens.spacing.small
        Layout.rightMargin: Tokens.padding.extraSmall
        text: {
            const devices = Bluetooth.devices.values;
            const connected = devices.filter(d => d.connected).length;
            if (connected > 0)
                // TRANSLATORS: %n = total paired devices, %1 = how many of them are connected
                return Tr.trN("%n device available (%1 connected)", "%n devices available (%1 connected)", devices.length).arg(connected);
            return Tr.trN("%n device available", "%n devices available", devices.length);
        }
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    Repeater {
        id: deviceRepeater

        model: ScriptModel {
            values: [...Bluetooth.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name)).slice(0, 5)
        }

        ColumnLayout {
            id: deviceWrap

            required property int index
            required property BluetoothDevice modelData

            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            RowLayout {
                id: device

                readonly property BluetoothDevice modelData: deviceWrap.modelData
                readonly property bool loading: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                // BlueZ battery, or the accessory-channel one for AirPods (-1 = unknown)
                // Output node of this headset in its current profile (null when not connected)
                readonly property var sink: BluetoothAudio.sinkFor(modelData.address)
                readonly property bool muted: !!sink?.audio?.muted
                readonly property real battery: modelData.batteryAvailable ? modelData.battery : BluetoothAudio.batteryFor(modelData.address)
                // AirPods: { left, right, case } levels, null for every other device
                readonly property var pods: BluetoothAudio.podsFor(modelData.address)

                Layout.fillWidth: true
                Layout.rightMargin: Tokens.padding.extraSmall
                spacing: Tokens.spacing.small

                opacity: 0
                scale: 0.7

                Component.onCompleted: {
                    opacity = 1;
                    scale = 1;
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                Behavior on scale {
                    Anim {}
                }

                MaterialIcon {
                    text: Icons.getBluetoothIcon(device.modelData.icon)
                }

                StyledText {
                    Layout.leftMargin: Tokens.spacing.extraSmall
                    Layout.rightMargin: Tokens.spacing.extraSmall
                    Layout.fillWidth: true
                    text: device.modelData.name
                    elide: Text.ElideRight
                }

                StyledText {
                    visible: device.modelData.state === BluetoothDeviceState.Connected && !device.pods && device.battery >= 0
                    text: `${Math.round(device.battery * 100)}%`
                    color: device.battery < 0.2 ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }

                MaterialIcon {
                    visible: device.modelData.state === BluetoothDeviceState.Connected && !device.pods
                    text: device.battery >= 0 ? Icons.getBatteryIcon(device.battery) : "battery_unknown"
                    color: device.battery >= 0 && device.battery < 0.2 ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                }

                // Mute toggle: filled when this headset's output is muted
                StyledRect {
                    visible: device.modelData.state === BluetoothDeviceState.Connected && !!device.sink?.audio
                    implicitWidth: implicitHeight
                    implicitHeight: muteIcon.implicitHeight + Tokens.padding.extraSmall

                    radius: Tokens.rounding.full
                    color: Qt.alpha(Colours.palette.m3errorContainer, device.muted ? 1 : 0)

                    Behavior on color {
                        CAnim {}
                    }

                    StateLayer {
                        color: device.muted ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurface
                        onClicked: device.sink.audio.muted = !device.sink.audio.muted
                    }

                    MaterialIcon {
                        id: muteIcon

                        anchors.centerIn: parent
                        animate: true
                        text: device.muted ? "volume_off" : "volume_up"
                        color: device.muted ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurface
                    }
                }

                StyledRect {
                    id: connectBtn

                    implicitWidth: implicitHeight
                    implicitHeight: connectIcon.implicitHeight + Tokens.padding.extraSmall

                    radius: Tokens.rounding.full
                    color: Qt.alpha(Colours.palette.m3primary, device.modelData.state === BluetoothDeviceState.Connected ? 1 : 0)

                    CircularIndicator {
                        anchors.fill: parent
                        running: device.loading
                    }

                    StateLayer {
                        color: device.modelData.state === BluetoothDeviceState.Connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        disabled: device.loading
                        onClicked: device.modelData.connected = !device.modelData.connected
                    }

                    MaterialIcon {
                        id: connectIcon

                        anchors.centerIn: parent
                        animate: true
                        text: device.modelData.connected ? "link_off" : "link"
                        color: device.modelData.state === BluetoothDeviceState.Connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                        opacity: device.loading ? 0 : 1

                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }
                }

                Loader {
                    visible: status === Loader.Ready
                    asynchronous: true
                    active: device.modelData.bonded
                    sourceComponent: Item {
                        implicitWidth: connectBtn.implicitWidth
                        implicitHeight: connectBtn.implicitHeight

                        StateLayer {
                            radius: Tokens.rounding.full
                            onClicked: device.modelData.forget()
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "delete"
                        }
                    }
                }
            }

            // Audio profile (music / calls / auto) for connected headsets with a PipeWire card
            Loader {
                Layout.fillWidth: true
                Layout.leftMargin: root.deviceTextInset
                Layout.rightMargin: Tokens.padding.extraSmall
                Layout.topMargin: Tokens.spacing.extraSmall
                Layout.bottomMargin: Tokens.spacing.medium
                active: deviceWrap.modelData.state === BluetoothDeviceState.Connected && !!BluetoothAudio.cardFor(deviceWrap.modelData.address)
                visible: active

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.medium

                    PodsStrip {
                        pods: BluetoothAudio.podsFor(deviceWrap.modelData.address)
                    }

                    ModeSelector {
                        address: deviceWrap.modelData.address
                    }

                    OutputVolume {
                        sink: BluetoothAudio.sinkFor(deviceWrap.modelData.address)
                    }
                }
            }

            // Hairline under the name (inset past the leading icon), not after the last row
            Hairline {
                visible: deviceWrap.index < deviceRepeater.count - 1
                Layout.leftMargin: root.deviceTextInset
            }
        }
    }

    IconTextButton {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.medium
        inactiveColour: Colours.palette.m3primaryContainer
        inactiveOnColour: Colours.palette.m3onPrimaryContainer
        verticalPadding: Tokens.padding.extraSmall
        text: Tr.tr("Open settings")
        icon: "settings"

        onClicked: root.popouts.detachRequested("bluetooth")
    }

    // Plain progress ring: full background track and a rounded arc from 12 o'clock. (The stock
    // CircularProgress leaves a gap between arc and track, which looks off at the start.)
    component PodRing: Item {
        id: ring

        property real value
        property int strokeWidth: 4
        property color fgColour: Colours.palette.m3primary
        property color bgColour: Qt.alpha(Colours.palette.m3onSurface, 0.14)
        readonly property real radius: (Math.min(width, height) - strokeWidth) / 2

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: ring.bgColour
                strokeWidth: ring.strokeWidth

                PathAngleArc {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    radiusX: ring.radius
                    radiusY: ring.radius
                    startAngle: -90
                    sweepAngle: 359.99
                }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: ring.value > 0 ? ring.fgColour : "transparent"
                strokeWidth: ring.strokeWidth
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    radiusX: ring.radius
                    radiusY: ring.radius
                    startAngle: -90
                    sweepAngle: Math.max(0.1, Math.min(1, ring.value) * 359.99)
                }
            }
        }
    }

    // One AirPods component: progress ring (letter for a bud, icon for the case) + percentage.
    // "—" and an empty ring when it is not reported.
    component PodLevel: RowLayout {
        id: pod

        property string prefix
        property string icon
        required property real level
        readonly property bool low: level >= 0 && level < 0.2

        spacing: Tokens.spacing.small

        Item {
            implicitWidth: 32
            implicitHeight: 32

            PodRing {
                anchors.fill: parent
                value: pod.level >= 0 ? pod.level : 0
                fgColour: pod.low ? Colours.palette.m3error : Colours.palette.m3primary
                bgColour: Qt.alpha(Colours.palette.m3onSurface, 0.14)
            }

            StyledText {
                id: letter

                // Centre the glyph itself (not the line box): offset by its tight bounds
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: width / 2 - (glyph.tightBoundingRect.x + glyph.tightBoundingRect.width / 2)
                anchors.verticalCenterOffset: height / 2 - (metrics.ascent + glyph.tightBoundingRect.y + glyph.tightBoundingRect.height / 2)
                visible: pod.prefix.length > 0
                text: pod.prefix
                color: Colours.palette.m3onSurface
                font: Tokens.font.body.builders.small.weight(Font.Medium).build()

                FontMetrics {
                    id: metrics

                    font: letter.font
                }

                TextMetrics {
                    id: glyph

                    font: letter.font
                    text: letter.text
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: pod.icon.length > 0
                text: pod.icon
                scale: 0.7
                color: Colours.palette.m3onSurface
            }
        }

        StyledText {
            text: pod.level >= 0 ? `${Math.round(pod.level * 100)}%` : "—"
            color: pod.low ? Colours.palette.m3error : Colours.palette.m3onSurface
            font: Tokens.font.body.builders.small.weight(Font.Medium).build()
        }
    }

    // Left bud, right bud and case on one rounded strip (same look as the mode selector),
    // with the refresh button at the end.
    component PodsStrip: StyledRect {
        id: strip

        required property var pods

        visible: !!pods
        Layout.fillWidth: true
        implicitHeight: stripRow.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.full
        color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

        RowLayout {
            id: stripRow

            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.small
            spacing: 0

            Repeater {
                model: [
                    {
                        prefix: Tr.trCtx("L", "left earbud"),
                        key: "left"
                    },
                    {
                        prefix: Tr.trCtx("R", "right earbud"),
                        key: "right"
                    },
                    {
                        icon: "inventory_2",
                        key: "case"
                    }
                ]

                Item {
                    id: cell

                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: pod.implicitHeight

                    PodLevel {
                        id: pod

                        anchors.centerIn: parent
                        prefix: cell.modelData.prefix ?? ""
                        icon: cell.modelData.icon ?? ""
                        level: strip.pods?.[cell.modelData.key] ?? -1
                    }
                }
            }

            Item {
                implicitWidth: refreshIcon.implicitWidth + Tokens.padding.medium
                implicitHeight: implicitWidth

                StateLayer {
                    radius: Tokens.rounding.full
                    disabled: BluetoothAudio.pollingBattery
                    onClicked: BluetoothAudio.pollBattery(true)
                }

                MaterialIcon {
                    id: refreshIcon

                    anchors.centerIn: parent
                    text: "refresh"
                    color: Colours.palette.m3onSurfaceVariant
                    opacity: BluetoothAudio.pollingBattery ? 0.5 : 1

                    RotationAnimator on rotation {
                        running: BluetoothAudio.pollingBattery
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 900
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }
        }
    }

    component OutputVolume: RowLayout {
        id: vol

        required property var sink
        readonly property bool muted: !!sink?.audio?.muted

        // Only for a headset that is not the active output: for the active one this is the system volume
        visible: !!sink?.audio && sink !== Audio.sink
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        Item {
            implicitWidth: muteIcon.implicitWidth + Tokens.padding.small
            implicitHeight: implicitWidth

            StateLayer {
                radius: Tokens.rounding.full
                onClicked: vol.sink.audio.muted = !vol.sink.audio.muted
            }

            MaterialIcon {
                id: muteIcon

                anchors.centerIn: parent
                animate: true
                text: vol.muted ? "volume_off" : (vol.sink?.audio?.volume ?? 0) < 0.01 ? "volume_mute" : "volume_up"
                color: vol.muted ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
            }
        }

        StyledSlider {
            Layout.fillWidth: true
            implicitHeight: Tokens.padding.medium * 2

            value: vol.muted ? 0 : (vol.sink?.audio?.volume ?? 0)
            onInteraction: value => {
                vol.sink.audio.muted = false;
                vol.sink.audio.volume = Math.max(0, Math.min(1, value));
            }
        }

        StyledText {
            // Fixed width so the slider does not resize while dragging (100% vs 9%)
            Layout.preferredWidth: pctMetrics.width
            horizontalAlignment: Text.AlignRight
            text: vol.muted ? "—" : `${Math.round((vol.sink?.audio?.volume ?? 0) * 100)}%`
            color: vol.muted ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small

            TextMetrics {
                id: pctMetrics

                font: Tokens.font.body.small
                text: "100%"
            }
        }
    }

    component ModeSelector: StyledRect {
        id: sel

        required property string address
        readonly property string current: BluetoothAudio.modeFor(address)
        readonly property var modes: [
            {
                id: "music",
                icon: "music_note",
                label: Tr.tr("Music")
            },
            {
                id: "call",
                icon: "headset_mic",
                label: Tr.tr("Calls")
            },
            {
                id: "auto",
                icon: "auto_awesome",
                label: Tr.trCtx("Auto", "bluetooth audio mode")
            }
        ]
        readonly property int currentIndex: Math.max(0, modes.findIndex(m => m.id === current))
        readonly property real pad: Tokens.padding.extraSmall / 2

        Layout.fillWidth: true
        implicitHeight: segments.implicitHeight + pad * 2
        radius: Tokens.rounding.full
        color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

        StyledRect {
            readonly property real segWidth: segments.width / sel.modes.length

            x: sel.pad + sel.currentIndex * segWidth
            y: sel.pad
            width: segWidth
            height: parent.height - sel.pad * 2
            radius: Tokens.rounding.full
            color: Colours.palette.m3primary

            Behavior on x {
                Anim {}
            }

        }

        RowLayout {
            id: segments

            x: sel.pad
            y: sel.pad
            width: parent.width - sel.pad * 2
            spacing: 0
            uniformCellSizes: true

            Repeater {
                id: segRepeater

                model: sel.modes

                Item {
                    id: seg

                    required property var modelData
                    readonly property bool active: modelData.id === sel.current

                    Layout.fillWidth: true
                    implicitHeight: segRow.implicitHeight + Tokens.padding.extraSmall * 2

                    StateLayer {
                        radius: Tokens.rounding.full
                        color: seg.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                        onClicked: BluetoothAudio.setMode(sel.address, seg.modelData.id)
                    }

                    Row {
                        id: segRow

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.extraSmall / 2

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: seg.modelData.icon
                            color: seg.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant

                            Behavior on color {
                                CAnim {}
                            }
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: seg.modelData.label
                            color: seg.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small

                            Behavior on color {
                                CAnim {}
                            }
                        }
                    }
                }
            }
        }
    }

    component Hairline: StyledRect {
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        implicitHeight: 1
        color: Colours.palette.m3outlineVariant
        opacity: 0.4
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.medium

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle
        }
    }
}
