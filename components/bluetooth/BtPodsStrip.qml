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
                font: Tokens.font.body.builders.small.weight(Font.Medium).scale(0.85).build()

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
}
