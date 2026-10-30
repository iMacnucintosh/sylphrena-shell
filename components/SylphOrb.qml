pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes
import qs.components
import qs.services

// SoftBurst Sylphrena orb (SylphOrb) shared by lock, About, and other brand surfaces.
Item {
    id: root

    property bool listening: false
    property bool troubled: false
    property bool welcomed: false
    property int orbSize: 96

    // Absolute timings — not token multiples (those stay ~1–2s and feel unchanged).
    readonly property int breathMs: 2400
    readonly property int listenBreathMs: 900
    readonly property int haloMs: 3200
    readonly property int ringMs: 4800
    readonly property int ringStaggerMs: 1800
    readonly property int orbitMs: 28000
    readonly property int iconPx: Math.max(24, Math.round(orbSize * 0.68))

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
            color: Qt.alpha(Colours.palette.m3primary, 0.22)
            opacity: 0
            scale: 1

            SequentialAnimation {
                running: true
                loops: Animation.Infinite

                PauseAnimation {
                    duration: ring.index * root.ringStaggerMs
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: ring
                        property: "scale"
                        from: 1
                        to: 1.85
                        duration: root.ringMs
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: ring
                        property: "opacity"
                        from: 0.4
                        to: 0
                        duration: root.ringMs
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

                width: Tokens.spacing.small * (index % 2 === 0 ? 1.1 : 0.7)
                height: width
                radius: Tokens.rounding.full
                color: index % 2 === 0 ? Colours.palette.m3primary : Colours.palette.m3tertiary
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
        color: Qt.alpha(root.troubled ? Colours.palette.m3error : Colours.palette.m3primary, 0.2)
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
        color: root.troubled ? Colours.palette.m3errorContainer : root.listening ? Colours.palette.m3tertiaryContainer : Colours.palette.m3primaryContainer

        Behavior on color {
            CAnim {}
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: root.welcomed ? "favorite" : root.troubled ? "priority_high" : root.listening ? "hearing" : "auto_awesome"
            color: root.troubled ? Colours.palette.m3onErrorContainer : root.listening ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onPrimaryContainer
            // Bind to root.orbSize — parent.implicitSize can lag and Material Symbols
            // glyphs (esp. auto_awesome) need a large em size to read as “big”.
            fontStyle: Tokens.font.icon.size(root.iconPx).build()
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
            duration: root.breathMs
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: orb
            property: "scale"
            from: 1.05
            to: 1
            duration: root.breathMs
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
            duration: root.listenBreathMs
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: orb
            property: "scale"
            from: 1.1
            to: 1
            duration: root.listenBreathMs
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
            duration: root.haloMs
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: halo
            property: "scale"
            from: 1.1
            to: 0.94
            duration: root.haloMs
            easing.type: Easing.InOutSine
        }
    }

    NumberAnimation on orbitAngle {
        from: 0
        to: 360
        duration: root.orbitMs
        loops: Animation.Infinite
        running: true
        easing.type: Easing.Linear
    }
}
