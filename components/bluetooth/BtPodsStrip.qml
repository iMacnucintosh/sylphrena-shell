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

        Repeater {
            model: [
                {
                    prefix: "L",
                    key: "left"
                },
                {
                    prefix: "R",
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

                BtBatteryRing {
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
