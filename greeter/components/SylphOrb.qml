pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import M3Shapes
import qs.components
import qs.services

// SoftBurst Sylphrena orb — greeter twin of components/SylphOrb.qml
// (Theme tokens; greeter cannot import the shell Colours/Tokens tree).
// Shape morph mirrors Android Material You (same spring path as LoadingIndicator).
Item {
    id: root

    property bool listening: false
    property bool troubled: false
    property bool welcomed: false
    property int orbSize: 96

    readonly property int breathMs: 2400
    readonly property int listenBreathMs: 900
    readonly property int haloMs: 3200
    readonly property int ringMs: 4800
    readonly property int ringStaggerMs: 1800
    readonly property int orbitMs: 28000
    // Pixel size of the center glyph. Keep in step with components/SylphOrb.qml.
    readonly property int iconPx: Math.max(32, Math.round(orbSize * 0.45))

    readonly property list<int> morphShapes: [
        MaterialShape.SoftBurst,
        MaterialShape.Cookie9Sided,
        MaterialShape.Sunny,
        MaterialShape.Cookie4Sided,
        MaterialShape.Oval,
        MaterialShape.Pentagon,
        MaterialShape.Ghostish,
        MaterialShape.Clover4Leaf
    ]
    property int morphShapeIndex: 0
    property real morphCRotation: 0
    property real morphLRotation: 0
    property real morphThisLRotation: 0
    readonly property int morphAnimRotation: 50
    readonly property real morphScaleAmt: 0.1
    readonly property real morphStiffness: 180
    readonly property real morphDamping: 0.6
    readonly property real morphVisibilityThreshold: 0.075
    readonly property int morphIntervalMs: listening ? 700 : 1600
    readonly property real morphSpringDuration: {
        const wn = Math.sqrt(morphStiffness);
        const r = -morphDamping * wn;
        const c = 1 / Math.sqrt(1 - morphDamping * morphDamping);
        return Math.log(morphVisibilityThreshold / c) / r;
    }
    readonly property real morphSpringMaxVelocity: {
        const wn = Math.sqrt(morphStiffness);
        const z = morphDamping;
        const factor = Math.exp(-z * Math.acos(z) / Math.sqrt(1 - z * z));
        return wn * factor;
    }
    property bool morphSpringSettled: true

    property real orbitAngle: 0
    property real orbBreathScale: 1
    property real haloBreathScale: 1

    function morphSpring(t: real): var {
        const wn = Math.sqrt(morphStiffness);
        const za = morphDamping * wn;
        const wd = wn * Math.sqrt(1 - morphDamping * morphDamping);
        const r = za / wd;
        const pos = 1 - Math.exp(-za * t) * (Math.cos(wd * t) + r * Math.sin(wd * t));
        const vel = Math.exp(-za * t) * (wn * wn / wd) * Math.sin(wd * t);
        return [pos, vel];
    }

    function advanceMorph(): void {
        orb.beginBatchUpdate();
        orb.fromShape = orb.toShape;
        morphShapeIndex = (morphShapeIndex + 1) % morphShapes.length;
        orb.toShape = morphShapes[morphShapeIndex];
        orb.morphProgress = 0;

        morphLRotation = (morphLRotation + morphThisLRotation) % 360;
        morphThisLRotation = 0;
        orb.rotation = Qt.binding(() => morphCRotation + morphLRotation + morphThisLRotation);

        morphSpringSettled = false;
        morphElapsed.restart();
        orb.endBatchUpdate();
    }

    implicitWidth: orbSize * 1.55
    implicitHeight: orbSize * 1.55

    ElapsedTimer {
        id: morphElapsed
    }

    FrameAnimation {
        running: !root.morphSpringSettled
        onTriggered: {
            const t = morphElapsed.elapsed();
            if (t >= root.morphSpringDuration) {
                root.morphSpringSettled = true;
                orb.morphProgress = 1;
                orb.scale = 1;
                root.morphThisLRotation = root.morphAnimRotation;
            } else {
                const [pos, vel] = root.morphSpring(t);
                orb.morphProgress = Math.min(1, pos);
                root.morphThisLRotation = pos * root.morphAnimRotation;
                orb.scale = 1 + vel * root.morphScaleAmt / root.morphSpringMaxVelocity;
            }
        }
    }

    Timer {
        interval: root.morphIntervalMs
        repeat: true
        triggeredOnStart: true
        running: true
        onTriggered: root.advanceMorph()
    }

    Repeater {
        model: 2

        MaterialShape {
            id: ring

            required property int index

            anchors.centerIn: parent
            implicitSize: root.orbSize
            fromShape: orb.fromShape
            toShape: orb.toShape
            morphProgress: orb.morphProgress
            rotation: orb.rotation
            color: Qt.alpha(Theme.palette.m3primary, 0.22)
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

    Item {
        anchors.centerIn: parent
        width: root.orbSize * 1.16
        height: width
        scale: root.haloBreathScale

        MaterialShape {
            id: halo

            anchors.centerIn: parent
            implicitSize: root.orbSize * 1.16
            fromShape: orb.fromShape
            toShape: orb.toShape
            morphProgress: orb.morphProgress
            rotation: orb.rotation
            color: Qt.alpha(root.troubled ? Theme.palette.m3error : Theme.palette.m3primary, 0.2)
            opacity: 0.8

            Behavior on color {
                CAnim {}
            }
        }
    }

    Item {
        anchors.centerIn: parent
        width: root.orbSize
        height: width
        scale: root.orbBreathScale

        MaterialShape {
            id: orb

            anchors.centerIn: parent
            implicitSize: root.orbSize
            toShape: root.morphShapes[0]
            color: root.troubled ? Theme.palette.m3errorContainer : root.listening ? Theme.palette.m3tertiaryContainer : Theme.palette.m3primaryContainer
            rotation: root.morphCRotation + root.morphLRotation + root.morphThisLRotation

            Behavior on color {
                CAnim {}
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: root.welcomed ? "favorite" : root.troubled ? "priority_high" : root.listening ? "hearing" : "auto_awesome"
            color: root.troubled ? Theme.palette.m3onErrorContainer : root.listening ? Theme.palette.m3onTertiaryContainer : Theme.palette.m3onPrimaryContainer
            iconSize: root.iconPx
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
            target: root
            property: "orbBreathScale"
            from: 1
            to: 1.05
            duration: root.breathMs
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "orbBreathScale"
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
            target: root
            property: "orbBreathScale"
            from: 1
            to: 1.1
            duration: root.listenBreathMs
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "orbBreathScale"
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
            target: root
            property: "haloBreathScale"
            from: 0.94
            to: 1.1
            duration: root.haloMs
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "haloBreathScale"
            from: 1.1
            to: 0.94
            duration: root.haloMs
            easing.type: Easing.InOutSine
        }
    }

    RotationAnimation on morphCRotation {
        running: true
        from: 0
        to: 360
        easing.type: Easing.Linear
        loops: Animation.Infinite
        duration: 12000
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
