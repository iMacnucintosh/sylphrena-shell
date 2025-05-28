import "root:/config"
import Quickshell
import QtQuick

Item {
    id: root

    required property bool visibility

    visible: height > 0
    implicitHeight: 0
    implicitWidth: content.implicitWidth + BorderConfig.rounding

    states: State {
        name: "visible"
        when: root.visibility

        PropertyChanges {
            root.implicitHeight: content.implicitHeight
        }
    }

    transitions: Transition {
        NumberAnimation {
            target: root
            property: "implicitHeight"
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    Content {
        id: content
    }
}
