pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.lock

// Sylphrena — same honorspren companion as the greeter, wired to PAM.
StyledRect {
    id: root

    required property var lock

    readonly property var pam: lock.pam
    readonly property string companionName: "Sylphrena"
    readonly property bool listening: pam.passwd.active || pam.fprint.active || pam.howdy.active
    readonly property bool welcomed: lock.unlocking
    readonly property bool troubled: pam.state === Pam.Failed || pam.state === Pam.Error || pam.state === Pam.MaxTries || !!pam.lockMessage
    readonly property string displayName: "Manuel"

    readonly property string greeting: {
        const h = Time.hours;
        if (h >= 6 && h < 12)
            return Tr.tr("Good morning");
        if (h >= 12 && h < 21)
            return Tr.tr("Good afternoon");
        return Tr.tr("Good evening");
    }

    readonly property var idleLines: [
        Tr.tr("There you are! I was looking for you in the winds"),
        Tr.tr("Life before death"),
        Tr.tr("Strength before weakness"),
        Tr.tr("Journey before destination"),
        Tr.tr("The sky is still… a good moment for the journey"),
        Tr.tr("I can wait. Spren are patient… sometimes"),
        Tr.tr("Your bond with this machine is not closed yet"),
        Tr.tr("Tell me a secret: the password will do")
    ]

    readonly property string liveLine: {
        if (root.welcomed)
            return Tr.tr("The bond closes! Welcome home, %1").arg(root.displayName);
        if (root.listening)
            return Tr.tr("I'm listening… is it really you?");
        if (root.troubled)
            return Tr.tr("That wasn't very honorable. Let's try again");
        return root.idleLines[root.statusIndex];
    }

    property int statusIndex: 0
    property int typedLen: 0
    property string typedText: ""
    property bool showCaret: false
    property int dotIndex: 0
    property real orbitAngle: 0

    clip: true
    radius: Tokens.rounding.medium
    bottomRightRadius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    onLiveLineChanged: {
        root.typedLen = 0;
        root.typedText = "";
        root.showCaret = true;
        typeTimer.restart();
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - Tokens.padding.extraLarge * 2
        spacing: Tokens.spacing.extraLargeIncreased

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.medium

            Item {
                id: orbStage

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: orbSize * 1.55
                Layout.preferredHeight: orbSize * 1.55

                readonly property int orbSize: Math.round(Math.min(118, Math.min(root.width, root.height) * 0.26))

                Repeater {
                    model: 2

                    MaterialShape {
                        id: ring

                        required property int index

                        anchors.centerIn: parent
                        implicitSize: orbStage.orbSize
                        shape: MaterialShape.SoftBurst
                        color: Qt.alpha(Colours.palette.m3primary, 0.22)
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

                Item {
                    anchors.centerIn: parent
                    width: orbStage.orbSize * 1.35
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
                    implicitSize: orbStage.orbSize * 1.16
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
                    implicitSize: orbStage.orbSize
                    shape: root.listening ? MaterialShape.SoftBurst : MaterialShape.Cookie4Sided
                    color: root.troubled ? Colours.palette.m3errorContainer : root.listening ? Colours.palette.m3tertiaryContainer : Colours.palette.m3primaryContainer

                    Behavior on color {
                        CAnim {}
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.welcomed ? "favorite" : root.troubled ? "priority_high" : root.listening ? "hearing" : "auto_awesome"
                        color: root.troubled ? Colours.palette.m3onErrorContainer : root.listening ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onPrimaryContainer
                        fontStyle: Tokens.font.icon.size(Math.round(parent.implicitSize * 0.38)).build()
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
                        duration: Tokens.anim.durations.expressiveDefaultEffects * 5
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: orb
                        property: "scale"
                        from: 1.05
                        to: 1
                        duration: Tokens.anim.durations.expressiveDefaultEffects * 5
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
                        duration: Math.round(Tokens.anim.durations.expressiveDefaultEffects * 6.5)
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: halo
                        property: "scale"
                        from: 1.1
                        to: 0.94
                        duration: Math.round(Tokens.anim.durations.expressiveDefaultEffects * 6.5)
                        easing.type: Easing.InOutSine
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.companionName
                color: Colours.palette.m3secondary
                font: Tokens.font.body.builders.small.weight(Font.DemiBold).letterSpacing(1.4).build()
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
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: `${root.greeting},`
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.title.medium
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.displayName
                    color: Colours.palette.m3primary
                    font: Tokens.font.headline.builders.small.weight(Font.DemiBold).build()
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.large

            StyledText {
                id: status

                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.font.body.medium.pointSize * 2.4
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignTop
                wrapMode: Text.WordWrap
                text: root.typedText + (root.showCaret ? "▍" : "")
                color: root.troubled ? Colours.palette.m3error : Colours.palette.m3secondary
                font: Tokens.font.body.medium

                Behavior on color {
                    CAnim {}
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.spacing.small
                visible: !root.welcomed

                Repeater {
                    model: 3

                    StyledRect {
                        required property int index

                        implicitWidth: Tokens.spacing.small
                        implicitHeight: implicitWidth
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primary
                        opacity: root.dotIndex === index ? 1 : 0.25

                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }
                }
            }
        }
    }

    NumberAnimation on orbitAngle {
        from: 0
        to: 360
        duration: 14000
        loops: Animation.Infinite
        running: true
        easing.type: Easing.Linear
    }

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
