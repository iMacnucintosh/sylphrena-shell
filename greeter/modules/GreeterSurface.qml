pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.modules
import qs.services

// Shared lock-layout surface used by the real layershell greeter and the
// FloatingWindow demo preview.
Item {
    id: root

    required property real screenHeight
    required property real screenWidth

    // Solid theme fill first — never leave the greeter as a blank black void.
    StyledRect {
        anchors.fill: parent
        color: Theme.palette.m3surface
    }

    Image {
        id: background

        anchors.fill: parent
        source: `file://${Theme.wallpaper}`
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: true
        opacity: 0.85
    }

    // Opaque surface card with the lock layout (minus media/notifs).
    Item {
        id: lockContent

        readonly property int size: lockIcon.implicitHeight + Theme.spacing.large * 4
        readonly property int radius: size / 4
        readonly property real targetW: root.screenHeight * Theme.lock.heightMult * Theme.lock.ratio
        readonly property real targetH: root.screenHeight * Theme.lock.heightMult

        anchors.centerIn: parent
        implicitWidth: targetW
        implicitHeight: targetH
        rotation: 0
        scale: 1

        StyledRect {
            id: lockBg

            anchors.fill: parent
            color: Theme.palette.m3surface
            radius: Theme.rounding.extraLarge * 1.5
        }

        MaterialIcon {
            id: lockIcon

            anchors.centerIn: parent
            text: "lock"
            iconSize: Theme.font.iconExtraLarge * 4
            font.weight: Font.Bold
            opacity: 0
            visible: false
        }

        Content {
            id: content

            anchors.centerIn: parent
            width: root.screenHeight * Theme.lock.heightMult * Theme.lock.ratio - Theme.spacing.extraLargeIncreased
            height: root.screenHeight * Theme.lock.heightMult - Theme.spacing.extraLargeIncreased

            screenHeight: root.screenHeight
            screenWidth: root.screenWidth

            opacity: 1
            scale: 1
        }
    }

    // Demo banner so we never confuse a session window with the real greeter.
    StyledRect {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Theme.spacing.large
        visible: Theme.demo
        color: Theme.palette.m3secondaryContainer
        radius: Theme.rounding.full
        implicitWidth: demoLabel.implicitWidth + Theme.spacing.large * 2
        implicitHeight: demoLabel.implicitHeight + Theme.spacing.small * 2
        z: 10

        StyledText {
            id: demoLabel

            anchors.centerIn: parent
            text: "Demo del greeter — contraseña cualquiera / «fail» para error · Esc cierra"
            color: Theme.palette.m3onSecondaryContainer
            font.pixelSize: Theme.font.bodySmall
        }
    }

    // Unlock: fade the lock card, keep the wallpaper. greetd must kill this
    // compositor before starting the session, so a GIF cannot cover the gap.
    // The last committed wallpaper frame is what amdgpu usually holds until
    // the user Hyprland paints — better than an intentional black curtain.
    states: State {
        when: Auth.success
        PropertyChanges {
            target: lockContent
            opacity: 0
            scale: 0.98
        }
        PropertyChanges {
            target: content
            opacity: 0
        }
    }

    transitions: Transition {
        Anim {
            target: lockContent
            property: "opacity"
            duration: 180
            type: Anim.FastEffects
        }
        Anim {
            target: lockContent
            property: "scale"
            duration: 180
            type: Anim.FastEffects
        }
        Anim {
            target: content
            property: "opacity"
            duration: 180
            type: Anim.FastEffects
        }
    }

    Timer {
        interval: 200
        running: Auth.success && !Auth.launchRequested
        onTriggered: Auth.launch()
    }

    // Fullscreen blackout before poweroff/reboot.
    Rectangle {
        anchors.fill: parent
        color: "black"
        z: 9999
        visible: Shutdown.armed
        opacity: Shutdown.armed ? 1 : 0
    }
}
