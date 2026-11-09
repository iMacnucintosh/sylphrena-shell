pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services

StyledRect {
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
