pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Sylphrena.Components
import Sylphrena.Config
import Sylphrena.I18n
import Sylphrena.State
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus
import qs.modules.bar.popouts as BarPopouts

StyledRect {
    id: root

    required property var props
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts

    readonly property bool showRecorderQuickAccess: Config.utilities.cards.recorder
    readonly property var quickToggles: {
        const seenIds = new Set();

        return Config.utilities.quickToggles.values.filter(item => {
            if (!item.enabled || seenIds.has(item.id))
                return false;

            // TODO: hide wallpaper playing toggle if wallpaper is live

            if (item.id === "vpn")
                return GlobalConfig.utilities.vpn.selectedProvider.length > 0;

            seenIds.add(item.id);
            return true;
        });
    }
    readonly property int splitIndex: Math.ceil(quickToggles.length / 2)
    readonly property bool needExtraRow: quickToggles.length > 6

    implicitHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        StyledText {
            text: Tr.tr("Quick toggles")
            font: Tokens.font.body.medium
        }

        QuickToggleRow {
            model: root.needExtraRow ? root.quickToggles.slice(0, root.splitIndex) : root.quickToggles
        }

        QuickToggleRow {
            visible: root.needExtraRow
            model: root.needExtraRow ? root.quickToggles.slice(root.splitIndex) : []
        }

        // Full-width record quick access: start fullscreen | expand full card.
        Loader {
            Layout.fillWidth: true
            active: root.showRecorderQuickAccess
            visible: active
            sourceComponent: RecordQuickAccess {}
        }
    }

    component RecordQuickAccess: RowLayout {
        id: recordQuick

        spacing: Math.floor(Tokens.spacing.extraSmall / 2)

        readonly property color colour: Colours.palette.m3primary
        readonly property color textColour: Colours.palette.m3onPrimary
        readonly property color disabledColour: Qt.alpha(Colours.palette.m3onSurface, 0.1)
        readonly property color disabledTextColour: Qt.alpha(Colours.palette.m3onSurface, 0.38)
        readonly property bool startDisabled: Recorder.running || Recorder.arming
        readonly property bool cardExpanded: root.props.recordingCardExpanded || Recorder.running
        readonly property real verticalPadding: Tokens.padding.small

        StyledRect {
            Layout.fillWidth: true
            radius: implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
            topRightRadius: Tokens.rounding.medium / 2
            bottomRightRadius: Tokens.rounding.medium / 2
            color: recordQuick.startDisabled ? recordQuick.disabledColour : recordQuick.colour

            implicitHeight: expandChip.implicitHeight

            StateLayer {
                topRightRadius: parent.topRightRadius
                bottomRightRadius: parent.bottomRightRadius
                color: recordQuick.textColour
                disabled: recordQuick.startDisabled
                onClicked: Recorder.start()
            }

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 1
                    text: "screen_record"
                    color: recordQuick.startDisabled ? recordQuick.disabledTextColour : recordQuick.textColour
                    fill: 1
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Tr.tr("Record screen")
                    color: recordQuick.startDisabled ? recordQuick.disabledTextColour : recordQuick.textColour
                    font: Tokens.font.body.medium
                }
            }
        }

        StyledRect {
            id: expandChip

            radius: implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
            topLeftRadius: recordQuick.cardExpanded ? implicitHeight / 2 * Math.min(1, Tokens.rounding.scale) : Tokens.rounding.medium / 2
            bottomLeftRadius: topLeftRadius
            color: recordQuick.colour

            implicitWidth: implicitHeight
            implicitHeight: expandIcon.implicitHeight + recordQuick.verticalPadding * 2

            StateLayer {
                rect.topLeftRadius: parent.topLeftRadius
                rect.bottomLeftRadius: parent.bottomLeftRadius
                color: recordQuick.textColour
                disabled: Recorder.running
                onClicked: root.props.recordingCardExpanded = !root.props.recordingCardExpanded
            }

            MaterialIcon {
                id: expandIcon

                anchors.centerIn: parent
                anchors.horizontalCenterOffset: recordQuick.cardExpanded ? 0 : -Math.floor(recordQuick.verticalPadding / 4)
                text: "expand_more"
                color: recordQuick.textColour
                rotation: recordQuick.cardExpanded ? 180 : 0

                Behavior on rotation {
                    Anim {}
                }

                Behavior on anchors.horizontalCenterOffset {
                    Anim {}
                }
            }

            Behavior on topLeftRadius {
                Anim {}
            }
        }
    }

    component QuickToggleRow: ButtonRow {
        property alias model: repeater.model

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        Repeater {
            id: repeater

            delegate: DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "wifi"
                    delegate: Toggle {
                        icon: "wifi"
                        checked: Nmcli.wifiEnabled
                        onClicked: Nmcli.toggleWifi()
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: Toggle {
                        icon: "bluetooth"
                        checked: Bluetooth.defaultAdapter?.enabled ?? false
                        onClicked: {
                            const adapter = Bluetooth.defaultAdapter;
                            if (adapter)
                                adapter.enabled = !adapter.enabled;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "mic"
                    delegate: Toggle {
                        icon: "mic"
                        checked: !Audio.sourceMuted
                        onClicked: {
                            const audio = Audio.source?.audio;
                            if (audio)
                                audio.muted = !audio.muted;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "settings"
                    delegate: Toggle {
                        icon: "settings"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        isToggle: false
                        onClicked: {
                            root.screenState.utilities = false;
                            WindowFactory.create();
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "keepAwake"
                    delegate: Toggle {
                        icon: "coffee"
                        checked: RuntimeState.inhibitIdle
                        onClicked: RuntimeState.inhibitIdle = !RuntimeState.inhibitIdle
                    }
                }
                DelegateChoice {
                    roleValue: "gameMode"
                    delegate: Toggle {
                        icon: "fit_screen"
                        checked: RuntimeState.gameMode
                        onClicked: RuntimeState.gameMode = !RuntimeState.gameMode
                    }
                }
                DelegateChoice {
                    roleValue: "wallpaperPlaying"
                    delegate: Toggle {
                        icon: "smart_display"
                        checked: PersistentState.wallpaperPlaying
                        onClicked: PersistentState.wallpaperPlaying = !PersistentState.wallpaperPlaying
                    }
                }
                DelegateChoice {
                    roleValue: "dnd"
                    delegate: Toggle {
                        icon: "notifications_off"
                        checked: PersistentState.doNotDisturb
                        onClicked: PersistentState.doNotDisturb = !PersistentState.doNotDisturb
                    }
                }
                DelegateChoice {
                    roleValue: "vpn"
                    delegate: Toggle {
                        icon: "vpn_key"
                        checked: VPN.connected && VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        enabled: !VPN.connecting && !VPN.disconnecting
                        isToggle: VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        onClicked: VPN.toggle()
                    }
                }
            }
        }
    }

    component Toggle: IconButton {
        inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        fillWidth: true
        isToggle: true
        isRound: true
        shapeMorph: true
    }
}
