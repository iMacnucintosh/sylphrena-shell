pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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

    width: Math.max(360, Tokens.sizes.bar.networkWidth)
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

                MaterialIcon {
                    visible: device.modelData.state === BluetoothDeviceState.Connected
                    text: device.modelData.batteryAvailable ? Icons.getBatteryIcon(device.modelData.battery) : "battery_alert"
                    color: device.modelData.batteryAvailable && device.modelData.battery < 0.2 ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
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
                active: deviceWrap.modelData.state === BluetoothDeviceState.Connected && !!BluetoothAudio.cardFor(deviceWrap.modelData.address)
                visible: active

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.extraSmall

                    ModeSelector {
                        address: deviceWrap.modelData.address
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.small
                        text: BluetoothAudio.describe(deviceWrap.modelData.address)
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
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
