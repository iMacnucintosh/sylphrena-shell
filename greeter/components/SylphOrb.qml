pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes
import qs.components
import qs.services

// SoftBurst Sylphrena orb — greeter twin of components/SylphOrb.qml
// (Theme tokens; greeter cannot import the shell Colours/Tokens tree).
Item {
    id: root

    property bool listening: false
    property bool troubled: false
    property bool welcomed: false
    property int orbSize: 96

    property real orbitAngle: 0

    implicitWidth: orbSize * 1.55
    implicitHeight: orbSize * 1.55

    Repeater {
        model: 2

        MaterialShape {
            id: ring

            required property int index

            anchors.centerIn: parent
            implicitSize: root.orbSize
            shape: MaterialShape.SoftBurst
            color: Qt.alpha(Theme.palette.m3primary, 0.22)
            opacity: 0
            scale: 1

            SequentialAnimation {
                running: true
                loops: Animation.Infinite

                PauseAnimation {
                    duration: ring.index * 1200
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: ring
                        property: "scale"
                        from: 1
                        to: 1.85
                        duration: 3200
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: ring
                        property: "opacity"
                        from: 0.4
                        to: 0
                        duration: 3200
                        easing.type: Easing.OutQuad
                    }
                }
                ScriptAction {
                    script: {
                        ring.scale = 1;
                        ring.opacity = 0;
                    }
                }
            }
        }
    }

    Item {
        anchors.centerIn: parent
        width: root.orbSize * 1.35
        height: width
        rotation: root.orbitAngle

        Repeater {
            model: 5

            StyledRect {
                required property int index

                width: Theme.spacing.small * (index % 2 === 0 ? 1.1 : 0.7)
                height: width
                radius: Theme.rounding.full
                color: index % 2 === 0 ? Theme.palette.m3primary : Theme.palette.m3tertiary
                opacity: 0.35 + (index % 3) * 0.15
                x: parent.width / 2 + Math.cos(index * 1.256) * (parent.width / 2) - width / 2
                y: parent.height / 2 + Math.sin(index * 1.256) * (parent.height / 2) - height / 2
            }
        }
    }

    MaterialShape {
        id: halo

        anchors.centerIn: parent
        implicitSize: root.orbSize * 1.16
        shape: MaterialShape.SoftBurst
        color: Qt.alpha(root.troubled ? Theme.palette.m3error : Theme.palette.m3primary, 0.2)
        opacity: 0.8

        Behavior on color {
            CAnim {}
        }
    }

    MaterialShape {
        id: orb

        anchors.centerIn: parent
        implicitSize: root.orbSize
        shape: root.listening ? MaterialShape.SoftBurst : MaterialShape.Cookie4Sided
        color: root.troubled ? Theme.palette.m3errorContainer : root.listening ? Theme.palette.m3tertiaryContainer : Theme.palette.m3primaryContainer

        Behavior on color {
            CAnim {}
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: root.welcomed ? "favorite" : root.troubled ? "priority_high" : root.listening ? "hearing" : "auto_awesome"
            color: root.troubled ? Theme.palette.m3onErrorContainer : root.listening ? Theme.palette.m3onTertiaryContainer : Theme.palette.m3onPrimaryContainer
            iconSize: Math.round(parent.implicitSize * 0.5)
            fill: root.welcomed || root.listening ? 1 : 0

            Behavior on color {
                CAnim {}
            }
        }
    }

    SequentialAnimation {
        running: !root.listening
        loops: Animation.Infinite

        NumberAnimation {
            target: orb
            property: "scale"
            from: 1
            to: 1.05
            duration: Math.round(Theme.durations.extraLarge * 1.4)
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: orb
            property: "scale"
            from: 1.05
            to: 1
            duration: Math.round(Theme.durations.extraLarge * 1.4)
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation {
        running: root.listening
        loops: Animation.Infinite

        NumberAnimation {
            target: orb
            property: "scale"
            from: 1
            to: 1.1
            duration: 520
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: orb
            property: "scale"
            from: 1.1
            to: 1
            duration: 520
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation {
        running: true
        loops: Animation.Infinite

        NumberAnimation {
            target: halo
            property: "scale"
            from: 0.94
            to: 1.1
            duration: Math.round(Theme.durations.extraLarge * 1.8)
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: halo
            property: "scale"
            from: 1.1
            to: 0.94
            duration: Math.round(Theme.durations.extraLarge * 1.8)
            easing.type: Easing.InOutSine
        }
    }

    NumberAnimation on orbitAngle {
        from: 0
        to: 360
        duration: 19000
        loops: Animation.Infinite
        running: true
        easing.type: Easing.Linear
    }
}
