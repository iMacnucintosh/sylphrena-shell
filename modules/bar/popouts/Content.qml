import "root:/services"
import "root:/config"
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen

    anchors.centerIn: parent

    implicitWidth: Popouts.hasCurrent ? (content.children.find(c => c.shouldBeActive)?.implicitWidth ?? 0) + Appearance.padding.large * 2 : 0
    implicitHeight: (content.children.find(c => c.shouldBeActive)?.implicitHeight ?? 0) + Appearance.padding.large * 2

    Item {
        id: content

        anchors.fill: parent
        anchors.margins: Appearance.padding.large

        clip: true

        Popout {
            name: "activewindow"
            source: "ActiveWindow.qml"
        }

        Popout {
            name: "network"
            source: "Network.qml"
        }

        Popout {
            name: "bluetooth"
            source: "Bluetooth.qml"
        }

        Popout {
            name: "battery"
            source: "Battery.qml"
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

        opacity: 0
        scale: 0.8
        asynchronous: true

        states: State {
            name: "active"
            when: popout.shouldBeActive

            PropertyChanges {
                popout.active: true
                popout.opacity: 1
                popout.scale: 1
            }
        }

        transitions: [
            Transition {
                from: "active"
                to: ""

                SequentialAnimation {
                    Anim {
                        properties: "opacity,scale"
                        duration: Appearance.anim.durations.small
                    }
                    PropertyAction {
                        target: popout
                        property: "active"
                    }
                }
            },
            Transition {
                from: ""
                to: "active"

                SequentialAnimation {
                    PropertyAction {
                        target: popout
                        property: "active"
                    }
                    Anim {
                        properties: "opacity,scale"
                    }
                }
            }
        ]
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
