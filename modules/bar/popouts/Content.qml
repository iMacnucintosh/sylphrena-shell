import "root:/services"
import "root:/config"
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen

    anchors.centerIn: parent

    implicitWidth: Popouts.hasCurrent ? content.children.find(c => c.shouldBeActive).implicitWidth + Appearance.padding.large * 2 : 0
    implicitHeight: Popouts.hasCurrent ? content.children.find(c => c.shouldBeActive).implicitHeight + Appearance.padding.large * 2 : 0

    Item {
        id: content

        anchors.fill: parent
        anchors.margins: Appearance.padding.large

        clip: true

        Popout {
            name: "activewindow"
            sourceComponent: ActiveWindow {}
        }
    }

    Behavior on implicitWidth {
        Anim {
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    Behavior on implicitHeight {
        Anim {
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    component Popout: Loader {
        id: popout

        required property string name
        property bool shouldBeActive: Popouts.currentName === name

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right

        active: shouldBeActive
        asynchronous: true

        Behavior on active {
            SequentialAnimation {
                Anim {
                    target: popout
                    property: "opacity"
                    from: popout.shouldBeActive ? 1 : 0
                    to: popout.shouldBeActive ? 0 : 1
                    duration: popout.shouldBeActive ? 0 : Appearance.anim.durations.normal
                }
                PropertyAction {}
                Anim {
                    target: popout
                    property: "opacity"
                    from: popout.shouldBeActive ? 0 : 1
                    to: popout.shouldBeActive ? 1 : 0
                    duration: popout.shouldBeActive ? Appearance.anim.durations.normal : 0
                }
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
