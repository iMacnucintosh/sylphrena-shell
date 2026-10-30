pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.services
import qs.modules.lock

// Sylphrena — same wind-spirit companion as the greeter, wired to PAM.
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
        Tr.tr("Breath before silence"),
        Tr.tr("The crack before the steel"),
        Tr.tr("The steps before the goal"),
        Tr.tr("The sky is still… a good moment for the journey"),
        Tr.tr("I can wait. Wind spirits are patient… sometimes"),
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

            CompanionOrb {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                orbSize: Math.round(Math.min(118, Math.min(root.width, root.height) * 0.26))
                listening: root.listening
                troubled: root.troubled
                welcomed: root.welcomed
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
