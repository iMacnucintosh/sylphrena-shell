pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Sylphrena.Config
import qs.components
import qs.services

// One AirPods component: progress ring (letter for a bud, icon for the case) + percentage.
// "—" and an empty ring when it is not reported.
RowLayout {
    id: pod

    // Ring diameter (same everywhere: popout rows, AirPods strip, Nexus)
    property int size: 26
    property string prefix
    // Show the percentage (digits only) inside the ring instead of next to it
    property bool valueInside: false
    property string icon
    required property real level
    readonly property bool low: level >= 0 && level < 0.2

    spacing: Tokens.spacing.small

    Item {
        implicitWidth: pod.size
        implicitHeight: pod.size

        PodRing {
            anchors.fill: parent
            value: pod.level >= 0 ? pod.level : 0
            strokeWidth: pod.size >= 30 ? 4 : 3
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
            font: Tokens.font.body.builders.small.weight(Font.Medium).scale((pod.prefix.length > 2 ? 0.7 : 0.85) * Math.min(1, pod.size / 32 + 0.1)).build()

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

        // "Not reported" mark: a drawn dash (a text dash is never optically centred)
        Rectangle {
            anchors.centerIn: parent
            visible: pod.valueInside && pod.level < 0
            width: Math.round(pod.size * 0.32)
            height: 2
            radius: 1
            color: Colours.palette.m3onSurfaceVariant
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: pod.icon.length > 0
            text: pod.icon
            scale: 0.6
            color: Colours.palette.m3onSurface
        }
    }

    StyledText {
        visible: !pod.valueInside
        text: pod.level >= 0 ? `${Math.round(pod.level * 100)}%` : "—"
        color: pod.low ? Colours.palette.m3error : Colours.palette.m3onSurface
        font: Tokens.font.body.builders.small.weight(Font.Medium).build()
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
}
