pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.bluetooth
import qs.components.controls
import qs.modules.nexus
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property PopoutState popouts

    width: Math.max(480, Tokens.sizes.bar.networkWidth)
    spacing: Tokens.spacing.small
    // Hairline inset past the leading device icon
    readonly property real deviceTextInset: Tokens.font.icon.small.pointSize + Tokens.spacing.small + Tokens.spacing.extraSmall

    RowLayout {
        Layout.topMargin: Tokens.padding.medium
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Bluetooth")
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        // Opens Nexus on the connected devices page
        Item {
            implicitWidth: gearIcon.implicitWidth + Tokens.padding.small
            implicitHeight: implicitWidth

            StateLayer {
                radius: Tokens.rounding.full
                onClicked: {
                    root.popouts.hasCurrent = false;
                    WindowFactory.openPage("bluetooth");
                }
            }

            MaterialIcon {
                id: gearIcon

                anchors.centerIn: parent
                text: "settings"
                color: Colours.palette.m3onSurfaceVariant
            }
        }
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

    // Separates the adapter toggles from the device list
    Hairline {
        Layout.topMargin: Tokens.spacing.small
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
                // This headset is the system's active output (where the sound is going right now)
                readonly property bool playing: !!sink && sink === Audio.sink
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

                // Accent circle behind the icon when this headset is the active output (same look as
                // the connect button). The circle overflows the cell so the row layout does not shift.
                Item {
                    implicitWidth: deviceIcon.implicitWidth
                    implicitHeight: deviceIcon.implicitHeight

                    StyledRect {
                        anchors.centerIn: parent
                        width: height
                        height: deviceIcon.implicitHeight + Tokens.padding.extraSmall
                        radius: Tokens.rounding.full
                        color: Qt.alpha(Colours.palette.m3primary, device.playing ? 1 : 0)

                        Behavior on color {
                            CAnim {}
                        }
                    }

                    MaterialIcon {
                        id: deviceIcon

                        anchors.centerIn: parent
                        text: Icons.getBluetoothIcon(device.modelData.icon)
                        color: device.playing ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                        Behavior on color {
                            CAnim {}
                        }
                    }
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

                // Audio mode (music / calls / auto), small and icon-only, on the name row
                BtModeSelector {
                    visible: device.modelData.state === BluetoothDeviceState.Connected && !!BluetoothAudio.cardFor(device.modelData.address)
                    address: device.modelData.address
                    showLabels: false
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

            // Battery levels (AirPods) below the name row
            Loader {
                Layout.fillWidth: true
                Layout.leftMargin: root.deviceTextInset
                Layout.rightMargin: Tokens.padding.extraSmall
                Layout.topMargin: Tokens.spacing.extraSmall
                Layout.bottomMargin: Tokens.spacing.medium
                // AirPods levels, only when the headset reports them
                active: deviceWrap.modelData.state === BluetoothDeviceState.Connected && !!device.pods
                visible: active

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.small

                    BtPodsStrip {
                        pods: BluetoothAudio.podsFor(deviceWrap.modelData.address)
                        plain: true
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
