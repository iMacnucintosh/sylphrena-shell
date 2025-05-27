pragma ComponentBehavior: Bound

import "root:/widgets"
import "root:/services"
import "root:/utils"
import "root:/config"
import QtQuick

Item {
    id: root

    property color colour: Colours.palette.m3primary

    implicitWidth: child.implicitWidth
    implicitHeight: child.implicitHeight

    Item {
        id: child

        anchors.centerIn: parent

        clip: true
        implicitWidth: Math.max(icon.implicitWidth, text.implicitHeight)
        implicitHeight: icon.implicitHeight + text.implicitWidth + text.anchors.topMargin

        MaterialIcon {
            id: icon

            animate: true
            text: Icons.getAppCategoryIcon(Hyprland.activeClient?.wmClass, "desktop_windows")
            color: root.colour

            anchors.horizontalCenter: parent.horizontalCenter
        }

        StyledText {
            id: text

            anchors.horizontalCenter: icon.horizontalCenter
            anchors.top: icon.bottom
            anchors.topMargin: Appearance.spacing.small

            text: metrics.elidedText
            font.pointSize: metrics.font.pointSize
            font.family: metrics.font.family
            color: root.colour

            transform: Rotation {
                angle: 90
                origin.x: text.implicitHeight / 2
                origin.y: text.implicitHeight / 2
            }

            width: implicitHeight
            height: implicitWidth
        }

        TextMetrics {
            id: metrics

            text: Hyprland.activeClient?.title ?? qsTr("Desktop")
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono
            elide: Qt.ElideRight
            elideWidth: root.height - icon.height
        }

        Behavior on implicitWidth {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }

        Behavior on implicitHeight {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    }
}
