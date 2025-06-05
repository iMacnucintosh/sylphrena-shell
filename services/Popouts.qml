pragma Singleton

import "root:/config"
import Quickshell
import QtQuick

Singleton {
    property string currentName
    property real currentCenter
    property bool hasCurrent

    Behavior on currentCenter {
        NumberAnimation {
            duration: Appearance.anim.durations.normal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }
}
