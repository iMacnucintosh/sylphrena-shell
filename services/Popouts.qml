pragma Singleton

import "root:/config"
import Quickshell
import QtQuick

Singleton {
    id: root

    property string currentName
    property real currentCenter
    property bool hasCurrent

    Behavior on currentCenter {
        enabled: root.hasCurrent

        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }
}
