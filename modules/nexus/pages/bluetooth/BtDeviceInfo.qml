pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Sylphrena.Components
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.bluetooth
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property BluetoothDevice device: nState.selectedBtDevice
    readonly property bool connected: device?.state === BluetoothDeviceState.Connected
    readonly property bool loading: device?.state === BluetoothDeviceState.Connecting || device?.state === BluetoothDeviceState.Disconnecting
    readonly property string address: device?.address ?? ""
    // Audio controls need a connected headset with a PipeWire card
    readonly property bool hasAudio: connected && !!BluetoothAudio.cardFor(address)
    // AirPods: { left, right, case } levels, null otherwise
    readonly property var pods: BluetoothAudio.podsFor(address)
    readonly property var card: BluetoothAudio.cardFor(address)
    readonly property string audioMode: BluetoothAudio.modeFor(address)
    readonly property list<MenuItem> musicQualityItems: [
        MenuItem {
            text: "AAC"
            value: "a2dp-sink"
        },
        MenuItem {
            text: "SBC-XQ"
            value: "a2dp-sink-sbc_xq"
        },
        MenuItem {
            text: "SBC"
            value: "a2dp-sink-sbc"
        }
    ]

    readonly property string statusText: {
        if (!device)
            return "";
        if (connected && device.batteryAvailable)
            // TRANSLATORS: %1 = battery level, already formatted as a percentage
            return Tr.trCtx("Connected • %1", "bluetooth device state with battery").arg(Strings.percentOne(device.battery));
        if (connected)
            return Tr.trCtx("Connected", "bluetooth device state");
        return device.bonded ? Tr.trCtx("Paired", "bluetooth device state") : Tr.trCtx("Not paired", "bluetooth device state");
    }

    onDeviceChanged: {
        // Auto close when device lost
        if (!device)
            nState.closeSubPage();
    }

    title: device?.name ?? Tr.trCtx("Device", "unnamed bluetooth device")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Big buttons
        ButtonRow {
            Layout.bottomMargin: Tokens.spacing.large - parent.spacing
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: Math.round(root.cappedWidth * 0.7)
            spacing: Tokens.spacing.small

            ButtonBase {
                id: forgetBtn

                fillWidth: true
                shapeMorph: true
                isRound: true

                inactiveColour: Colours.palette.m3errorContainer
                inactiveOnColour: Colours.palette.m3onErrorContainer

                implicitWidth: forgetBtnLayout.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: forgetBtnLayout.implicitHeight + Tokens.padding.medium * 2

                onClicked: {
                    root.device?.forget();
                    root.nState.closeSubPage();
                }

                ColumnLayout {
                    id: forgetBtnLayout

                    anchors.centerIn: parent
                    spacing: 0

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "delete"
                        color: forgetBtn.onColour
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Tr.trCtx("Forget", "button")
                        color: forgetBtn.onColour
                    }
                }
            }

            ButtonBase {
                id: connectBtn

                fillWidth: true
                shapeMorph: true
                isRound: true

                inactiveColour: Colours.palette.m3primaryContainer
                inactiveOnColour: Colours.palette.m3onPrimaryContainer
                stateLayer.disabled: root.loading

                implicitWidth: connectBtnContent.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: connectBtnContent.implicitHeight + Tokens.padding.medium * 2

                onClicked: root.device.connected = !root.connected

                AnimLoader {
                    id: connectBtnContent

                    anchors.centerIn: parent
                    sourceComp: root.loading ? loadingComp : textComp
                    outAnimType: Anim.SlowEffects
                    inAnimType: Anim.SlowEffects
                }

                Component {
                    id: loadingComp

                    LoadingIndicator {
                        implicitSize: connectBtn.height - Tokens.padding.large * 2
                    }
                }

                Component {
                    id: textComp

                    ColumnLayout {
                        spacing: 0

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.connected ? "close" : "add"
                            color: connectBtn.inactiveOnColour
                            fontStyle: Tokens.font.icon.medium
                            animate: true
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.connected ? Tr.trCtx("Disconnect", "button") : Tr.trCtx("Connect", "button")
                            color: connectBtn.inactiveOnColour
                            animate: true
                        }
                    }
                }
            }
        }

        // Audio profile, channel and output of the connected headset
        SectionHeader {
            visible: root.hasAudio
            first: true
            text: Tr.tr("Audio")
        }

        ConnectedRect {
            visible: root.hasAudio
            Layout.fillWidth: true
            first: true
            implicitHeight: modeLayout.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: modeLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Audio mode")
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.audioMode === "call" ? Tr.tr("Microphone always available, call quality") : root.audioMode === "music" ? Tr.tr("Best sound quality, no microphone") : Tr.tr("High quality until an app uses the microphone")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                }

                BtModeSelector {
                    address: root.address
                }
            }
        }

        InfoRow {
            visible: root.hasAudio
            label: Tr.tr("Channel")
            value: {
                const profile = root.card?.profile ?? "";
                const codec = BluetoothAudio.codecLabel(profile);
                return profile.startsWith("headset") ? Tr.tr("Calls · %1").arg(codec) : Tr.tr("High quality · %1").arg(codec);
            }
        }

        SelectRow {
            visible: root.hasAudio && BluetoothAudio.a2dpOptions(root.address).length > 1
            label: Tr.tr("Music quality")
            subtext: root.audioMode === "call" ? Tr.tr("Applies when the headset is in music mode") : Tr.tr("Codec used to play music")
            menuItems: root.musicQualityItems.filter(i => BluetoothAudio.a2dpOptions(root.address).includes(i.value))
            active: root.musicQualityItems.find(i => i.value === root.card?.profile) ?? root.musicQualityItems[0]
            onSelected: item => BluetoothAudio.setProfile(root.address, item.value)
        }

        ConnectedRect {
            visible: root.hasAudio && !!BluetoothAudio.sinkFor(root.address)?.audio
            Layout.fillWidth: true
            last: true
            implicitHeight: outputLayout.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: outputLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.trCtx("Output", "audio output")
                }

                BtOutputVolume {
                    sink: BluetoothAudio.sinkFor(root.address)
                    alwaysVisible: true
                }
            }
        }

        // Connection group
        ToggleRow {
            verticalPadding: Tokens.padding.large
            first: true
            text: Tr.trCtx("Trusted", "bluetooth device state")
            subtext: Tr.tr("Allow this device to connect automatically")
            checked: root.device?.trusted ?? false
            onToggled: {
                if (root.device)
                    root.device.trusted = checked;
            }
        }

        ToggleRow {
            verticalPadding: Tokens.padding.large
            text: Tr.trCtx("Blocked", "bluetooth device state")
            subtext: Tr.tr("Prevent this device from connecting")
            checked: root.device?.blocked ?? false
            onToggled: {
                if (root.device)
                    root.device.blocked = checked;
            }
        }

        ToggleRow {
            verticalPadding: Tokens.padding.large
            last: true
            text: Tr.tr("Wake allowed")
            subtext: Tr.tr("Allow this device to wake the system")
            checked: root.device?.wakeAllowed ?? false
            onToggled: {
                if (root.device)
                    root.device.wakeAllowed = checked;
            }
        }

        // Information
        ConnectedRect {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            Layout.fillWidth: true
            implicitHeight: batteryLayout.implicitHeight + Tokens.padding.large * 2
            first: true

            ColumnLayout {
                id: batteryLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Battery")
                    }

                    StyledText {
                        visible: !root.pods
                        text: root.device?.batteryAvailable ? Strings.percentOne(root.device.battery) : Tr.trCtx("Unavailable", "bluetooth device state")
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.small
                    }
                }

                BtPodsStrip {
                    pods: root.pods
                }

                Loader {
                    Layout.fillWidth: true
                    active: (root.device?.batteryAvailable ?? false) && !root.pods
                    visible: active
                    asynchronous: true

                    sourceComponent: StyledProgressBar {
                        implicitHeight: Tokens.padding.medium
                        value: root.device.battery
                    }
                }
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            implicitHeight: addrLayout.implicitHeight + Tokens.padding.large * 2
            last: true

            RowLayout {
                id: addrLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.trCtx("Address", "bluetooth MAC address")
                }

                StyledText {
                    text: root.device?.address ?? ""
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                }
            }
        }
    }
}
