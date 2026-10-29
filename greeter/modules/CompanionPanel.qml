pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import qs.components
import qs.services

// Sylphrena — wind-spirit companion with an original voice. M3 UI.
StyledRect {
    id: root

    readonly property string companionName: "Sylphrena"
    readonly property bool listening: Auth.busy
    readonly property bool welcomed: Auth.success
    readonly property bool troubled: !!Auth.message && !Auth.busy && !Auth.success

    readonly property string greeting: {
        const h = Time.now.getHours();
        if (h >= 6 && h < 12)
            return "Buenos días";
        if (h >= 12 && h < 21)
            return "Buenas tardes";
        return "Buenas noches";
    }

    // Curious wind-spirit voice: original lines, no quotes from any book.
    readonly property var idleLines: [
        "¡Ahí estás! Te estaba buscando entre los vientos",
        "El aliento antes que el silencio",
        "La grieta antes que el acero",
        "Los pasos antes que la meta",
        "El cielo está quieto… buen momento para la jornada",
        "Puedo esperar. Los espíritus del viento somos pacientes… a veces",
        "Tu vínculo con esta máquina aún no se ha cerrado",
        "Cuéntame un secreto: la contraseña basta"
    ]

    readonly property string liveLine: {
        if (root.welcomed)
            return "¡El vínculo se cierra! Bienvenido a casa, Manuel";
        if (root.listening)
            return "Escucho… ¿eres tú de verdad?";
        if (root.troubled)
            return "Eso no fue muy honorable. Probemos otra vez";
        return root.idleLines[root.statusIndex];
    }

    property int statusIndex: 0
    property int typedLen: 0
    property string typedText: ""
    property bool showCaret: false
    property int dotIndex: 0
    property real orbitAngle: 0

    radius: Theme.rounding.medium
    bottomRightRadius: Theme.rounding.extraLarge
    color: Theme.palette.m3surfaceContainer

    onLiveLineChanged: {
        root.typedLen = 0;
        root.typedText = "";
        root.showCaret = true;
        typeTimer.restart();
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - Theme.spacing.extraLarge * 2
        spacing: Theme.spacing.extraLargeIncreased

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing.medium

            Item {
                id: orbStage

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: orbSize * 1.55
                Layout.preferredHeight: orbSize * 1.55

                readonly property int orbSize: Math.round(Math.min(118, Math.min(root.width, root.height) * 0.26))

                // Sonar rings
                Repeater {
                    model: 2

                    MaterialShape {
                        id: ring

                        required property int index

                        anchors.centerIn: parent
                        implicitSize: orbStage.orbSize
                        shape: MaterialShape.SoftBurst
                        color: Qt.alpha(Theme.palette.m3primary, 0.22)
                        opacity: 0
                        scale: 1

                        SequentialAnimation {
                            running: true
                            loops: Animation.Infinite

                            PauseAnimation {
                                duration: ring.index * 900
                            }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: ring
                                    property: "scale"
                                    from: 1
                                    to: 1.85
                                    duration: 2400
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: ring
                                    property: "opacity"
                                    from: 0.4
                                    to: 0
                                    duration: 2400
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

                // Orbiting motes
                Item {
                    anchors.centerIn: parent
                    width: orbStage.orbSize * 1.35
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
                    implicitSize: orbStage.orbSize * 1.16
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
                    implicitSize: orbStage.orbSize
                    shape: root.listening ? MaterialShape.SoftBurst : MaterialShape.Cookie4Sided
                    color: root.troubled ? Theme.palette.m3errorContainer : root.listening ? Theme.palette.m3tertiaryContainer : Theme.palette.m3primaryContainer

                    Behavior on color {
                        CAnim {}
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.welcomed ? "favorite" : root.troubled ? "priority_high" : root.listening ? "hearing" : "auto_awesome"
                        color: root.troubled ? Theme.palette.m3onErrorContainer : root.listening ? Theme.palette.m3onTertiaryContainer : Theme.palette.m3onPrimaryContainer
                        iconSize: Math.round(parent.implicitSize * 0.38)
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
                        duration: Theme.durations.extraLarge
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: orb
                        property: "scale"
                        from: 1.05
                        to: 1
                        duration: Theme.durations.extraLarge
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
                        duration: 380
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: orb
                        property: "scale"
                        from: 1.1
                        to: 1
                        duration: 380
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
                        duration: Math.round(Theme.durations.extraLarge * 1.3)
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: halo
                        property: "scale"
                        from: 1.1
                        to: 0.94
                        duration: Math.round(Theme.durations.extraLarge * 1.3)
                        easing.type: Easing.InOutSine
                    }
                }
            }

            StyledText {
                id: nameLabel

                Layout.alignment: Qt.AlignHCenter
                text: root.companionName
                color: Theme.palette.m3secondary
                font.pixelSize: Theme.font.bodySmall
                font.weight: Font.DemiBold
                font.letterSpacing: 1.4
                opacity: 0.55

                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 0.45
                        to: 1
                        duration: 1600
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        from: 1
                        to: 0.45
                        duration: 1600
                        easing.type: Easing.InOutSine
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Theme.spacing.small
                spacing: Theme.spacing.extraSmall

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: `${root.greeting},`
                    color: Theme.palette.m3onSurfaceVariant
                    font.pixelSize: Theme.font.titleMedium
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Theme.displayName
                    color: Theme.palette.m3primary
                    font.pixelSize: Theme.font.headlineSmall
                    font.weight: Font.DemiBold
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing.large

            StyledText {
                id: status

                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.font.bodyMedium * 2.4
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignTop
                wrapMode: Text.WordWrap
                text: root.typedText + (root.showCaret ? "▍" : "")
                color: root.troubled ? Theme.palette.m3error : Theme.palette.m3secondary
                font.pixelSize: Theme.font.bodyMedium

                Behavior on color {
                    CAnim {}
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacing.small
                visible: !root.welcomed

                Repeater {
                    model: 3

                    StyledRect {
                        required property int index

                        implicitWidth: Theme.spacing.small
                        implicitHeight: implicitWidth
                        radius: Theme.rounding.full
                        color: Theme.palette.m3primary
                        opacity: root.dotIndex === index ? 1 : 0.25

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.durations.fastEffects
                            }
                        }
                    }
                }
            }
        }
    }

    // Orbit
    NumberAnimation on orbitAngle {
        from: 0
        to: 360
        duration: 14000
        loops: Animation.Infinite
        running: true
        easing.type: Easing.Linear
    }

    // Typewriter
    Timer {
        id: typeTimer

        interval: root.listening ? 18 : 28
        running: true
        repeat: true
        onTriggered: {
            if (root.typedLen >= root.liveLine.length) {
                root.showCaret = false;
                typeTimer.stop();
                return;
            }
            root.typedLen += 1;
            root.typedText = root.liveLine.slice(0, root.typedLen);
            root.showCaret = true;
        }
    }

    Timer {
        interval: 480
        running: typeTimer.running
        repeat: true
        onTriggered: root.showCaret = !root.showCaret
    }

    // Rotate idle lines (paused while typing / auth)
    Timer {
        interval: 5200
        running: !root.listening && !root.welcomed && !root.troubled
        repeat: true
        onTriggered: root.statusIndex = (root.statusIndex + 1) % root.idleLines.length
    }

    Timer {
        interval: root.listening ? 220 : 400
        running: !root.welcomed
        repeat: true
        onTriggered: root.dotIndex = (root.dotIndex + 1) % 3
    }

    Component.onCompleted: {
        root.typedLen = 0;
        root.typedText = "";
        typeTimer.start();
    }
}
