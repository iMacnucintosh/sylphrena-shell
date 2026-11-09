pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services

// Left bud, right bud and case on one rounded strip (same look as the mode selector),
// with the refresh button at the end.
StyledRect {
    id: strip

    required property var pods
    // No surface of its own (the popout); the Nexus page keeps the rounded strip
    property bool plain: false

    visible: !!pods
    Layout.fillWidth: true
    implicitHeight: stripRow.implicitHeight + Tokens.padding.small * 2
    radius: Tokens.rounding.full
    color: plain ? "transparent" : Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

    RowLayout {
        id: stripRow

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.small
        spacing: 0

        // Left bud | case | right bud, like the tabs of the mode selector
        Repeater {
            model: [
                {
                    label: "L",
                    key: "left"
                },
                {
                    icon: "inventory_2",
                    key: "case"
                },
                {
                    label: "R",
                    key: "right"
                }
            ]

            Item {
                id: cell

                required property var modelData
                readonly property real level: strip.pods?.[modelData.key] ?? -1

                Layout.fillWidth: true
                implicitHeight: cellRow.implicitHeight

                RowLayout {
                    id: cellRow

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.small

                    // What it is: bud letter or case icon; the level lives inside the ring
                    StyledText {
                        visible: !!cell.modelData.label
                        text: cell.modelData.label ?? ""
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                    }

                    MaterialIcon {
                        visible: !!cell.modelData.icon
                        text: cell.modelData.icon ?? ""
                        color: Colours.palette.m3onSurfaceVariant
                    }

                    BtBatteryRing {
                        size: 32
                        valueInside: true
                        prefix: cell.level >= 0 ? `${Math.round(cell.level * 100)}` : "—"
                        level: cell.level
                    }
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

                    // Rotated text is drawn unsmoothed: never leave the icon stopped at an angle
                    onRunningChanged: {
                        if (!running)
                            refreshIcon.rotation = 0;
                    }
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
