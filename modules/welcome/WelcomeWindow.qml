pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus
import qs.modules.nexus.common

// The welcome assistant window (see services/Welcome.qml): what Sylphrena is, what it offers, and
// the apps of its family that are worth installing. Four steps; skipping or finishing both count as seen.
FloatingWindow {
    id: win

    readonly property int stepCount: 4
    property int step: 0

    property bool done: false

    signal finished

    // Close the window (finishing, skipping or closing it by hand all end up here)
    function dismiss(): void {
        if (win.done)
            return;
        win.done = true;
        win.finished();
        win.destroy();
    }

    title: Tr.tr("Welcome to Sylphrena")
    color: Colours.tPalette.m3surface
    surfaceFormat.opaque: false
    implicitWidth: 880
    implicitHeight: 640
    minimumSize.width: 720
    minimumSize.height: 560

    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name

    onVisibleChanged: {
        if (!visible)
            win.dismiss();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.extraLarge
        spacing: Tokens.spacing.large

        // ---- Pages ----------------------------------------------------------------------
        Loader {
            id: pages

            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: [welcomePage, offerPage, companionsPage, donePage][win.step]

            onLoaded: fade.restart()

            NumberAnimation {
                id: fade

                target: pages.item
                property: "opacity"
                from: 0
                to: 1
                duration: Tokens.anim.durations.normal
            }
        }

        // ---- Footer ---------------------------------------------------------------------
        Item {
            Layout.fillWidth: true
            implicitHeight: buttons.implicitHeight

            // Step dots, centred whatever the buttons on the sides are
            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                Repeater {
                    model: win.stepCount

                    Rectangle {
                        required property int index

                        anchors.verticalCenter: parent.verticalCenter
                        width: index === win.step ? Tokens.padding.large : Tokens.padding.small
                        height: Tokens.padding.small
                        radius: height / 2
                        color: index === win.step ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                        Behavior on width {
                            Anim {}
                        }
                    }
                }
            }

            RowLayout {
                id: buttons

                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Tokens.spacing.medium

                TextButton {
                    visible: win.step < win.stepCount - 1
                    text: Tr.tr("Skip")
                    type: TextButton.Text
                    isRound: true
                    horizontalPadding: Tokens.padding.large
                    verticalPadding: Tokens.padding.small
                    onClicked: win.dismiss()
                }

                Item {
                    Layout.fillWidth: true
                }

                TextButton {
                    visible: win.step > 0
                    text: Tr.tr("Back")
                    type: TextButton.Tonal
                    isRound: true
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    onClicked: win.step--
                }

                TextButton {
                    text: win.step < win.stepCount - 1 ? Tr.tr("Next") : Tr.tr("Finish")
                    isRound: true
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    onClicked: win.step < win.stepCount - 1 ? win.step++ : win.dismiss()
                }
            }
        }
    }

    // ── 1 · Who Sylphrena is ──────────────────────────────────────────────────────────────
    Component {
        id: welcomePage

        ColumnLayout {
            spacing: Tokens.spacing.large

            Item {
                Layout.fillHeight: true
            }

            SylphOrb {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                orbSize: 168
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "Sylphrena"
                font: Tokens.font.headline.medium
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 560
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: Tr.tr("A Material You desktop shell for Hyprland, made to be yours: every look, shortcut and widget can be changed, and what you do not need can be left out.")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.large
            }

            // Who makes it
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.spacing.medium
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    // TRANSLATORS: %1 = the author's name on GitHub
                    text: Tr.tr("Made by %1").arg("iMacnucintosh")
                    font: Tokens.font.title.small
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    // TRANSLATORS: %1 = the name of the original project, %2 = its author
                    text: Tr.tr("A fork of %1 by %2").arg("caelestia-shell").arg("soramane")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.medium
                }
            }

            IconTextButton {
                Layout.alignment: Qt.AlignHCenter
                isRound: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.large
                verticalPadding: Tokens.padding.small
                icon: "open_in_new"
                text: "GitHub"
                onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/iMacnucintosh/sylphrena-shell"])
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    // ── 2 · What it offers ────────────────────────────────────────────────────────────────
    Component {
        id: offerPage

        ColumnLayout {
            spacing: Tokens.spacing.large

            ColumnLayout {
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    text: Tr.tr("What Sylphrena gives you")
                    font: Tokens.font.headline.medium
                }

                StyledText {
                    text: Tr.tr("A quick look. Everything is in Nexus, the settings window.")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                rowSpacing: Tokens.spacing.medium
                columnSpacing: Tokens.spacing.medium

                Repeater {
                    model: [
                        {
                            icon: "grid_view",
                            title: Tr.tr("Activities"),
                            text: Tr.tr("A look for each part of your day: wallpaper, colours and the apps pinned to its desktops.")
                        },
                        {
                            icon: "tune",
                            title: "Nexus",
                            text: Tr.tr("Every setting in one window, with search.")
                        },
                        {
                            icon: "space_dashboard",
                            title: Tr.tr("Dashboard"),
                            text: Tr.tr("Weather, music, performance and your widgets at a glance.")
                        },
                        {
                            icon: "palette",
                            title: "Material You",
                            text: Tr.tr("Colours that follow your wallpaper, in the shell and in your apps.")
                        },
                        {
                            icon: "extension",
                            title: Tr.tr("Extensions"),
                            text: Tr.tr("Add only what you need: widgets, VPN, games and more.")
                        },
                        {
                            icon: "lock",
                            title: Tr.tr("Lock and login"),
                            text: Tr.tr("A lock screen and a login screen that match the shell.")
                        }
                    ]

                    ConnectedRect {
                        id: card

                        required property var modelData

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        implicitHeight: cardCol.implicitHeight + Tokens.padding.large * 2
                        first: true
                        last: true

                        ColumnLayout {
                            id: cardCol

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Tokens.padding.large
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: card.modelData.icon
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.large
                                fill: 1
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: card.modelData.title
                                font: Tokens.font.title.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: card.modelData.text
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.small
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }

    // ── 3 · Apps of the family ────────────────────────────────────────────────────────────
    Component {
        id: companionsPage

        ColumnLayout {
            id: companions

            readonly property var seeker: Companions.find("seeker")
            readonly property bool installed: Companions.isInstalled("seeker")
            readonly property bool installing: Companions.installingId === "seeker"
            property bool askPassword: false

            function doInstall(): void {
                if (pass.text.length === 0)
                    return;
                Companions.install("seeker", pass.text);
                pass.text = "";
                companions.askPassword = false;
            }

            spacing: Tokens.spacing.large

            Component.onCompleted: Companions.check()

            ColumnLayout {
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    text: Tr.tr("Apps made for Sylphrena")
                    font: Tokens.font.headline.medium
                }

                StyledText {
                    text: Tr.tr("They follow the shell's theme. You can add them now or later.")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }
            }

            ConnectedRect {
                Layout.fillWidth: true
                first: true
                last: true
                implicitHeight: seekerCol.implicitHeight + Tokens.padding.large * 2

                ColumnLayout {
                    id: seekerCol

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            Layout.alignment: Qt.AlignVCenter
                            text: companions.seeker.icon
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.extraLarge
                            fill: 1
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: companions.seeker.name
                                font: Tokens.font.title.medium
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: companions.seeker.description
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.small
                                wrapMode: Text.WordWrap
                            }
                        }

                        // State of Seeker
                        MaterialIcon {
                            visible: companions.installed && !companions.installing
                            Layout.alignment: Qt.AlignVCenter
                            text: "check_circle"
                            color: Colours.palette.m3primary
                            fill: 1
                        }

                        StyledText {
                            visible: companions.installed && !companions.installing
                            Layout.alignment: Qt.AlignVCenter
                            text: Tr.trCtx("Installed", "an app is installed")
                            color: Colours.palette.m3primary
                            font: Tokens.font.label.large
                        }

                        TextButton {
                            visible: companions.installed && !companions.installing
                            Layout.alignment: Qt.AlignVCenter
                            type: TextButton.Tonal
                            isRound: true
                            horizontalPadding: Tokens.padding.large
                            verticalPadding: Tokens.padding.small
                            text: Tr.tr("Open")
                            onClicked: Companions.launch("seeker")
                        }

                        IconTextButton {
                            visible: !companions.installed && !companions.installing && !companions.askPassword
                            Layout.alignment: Qt.AlignVCenter
                            isRound: true
                            horizontalPadding: Tokens.padding.large
                            verticalPadding: Tokens.padding.small
                            icon: "download"
                            text: Tr.tr("Install")
                            onClicked: {
                                companions.askPassword = true;
                                Qt.callLater(() => pass.forceActiveFocus());
                            }
                        }
                    }

                    // Working
                    RowLayout {
                        Layout.fillWidth: true
                        visible: companions.installing
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: "hourglass_top"
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                switch (Companions.installStep) {
                                case "download":
                                    return Tr.tr("Downloading…");
                                case "deps":
                                    return Tr.tr("Installing what it needs…");
                                case "build":
                                    return Tr.tr("Building… this takes a minute");
                                case "install":
                                    return Tr.tr("Installing…");
                                }
                                return Tr.tr("Working…");
                            }
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                        }
                    }

                    // Password: it installs a system package
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: companions.askPassword && !companions.installing
                        spacing: Tokens.spacing.small

                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("It is installed as a system package, so it needs your password.")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledTextField {
                                id: pass

                                Layout.fillWidth: true
                                placeholderText: Tr.tr("Password")
                                leadingIcon: "key"
                                echoMode: TextInput.Password
                                onAccepted: companions.doInstall()
                                Keys.onEscapePressed: {
                                    pass.text = "";
                                    companions.askPassword = false;
                                }
                            }

                            TextButton {
                                isRound: true
                                type: TextButton.Tonal
                                horizontalPadding: Tokens.padding.large
                                verticalPadding: Tokens.padding.small
                                text: Tr.trCtx("Cancel", "button")
                                onClicked: {
                                    pass.text = "";
                                    companions.askPassword = false;
                                }
                            }

                            TextButton {
                                isRound: true
                                horizontalPadding: Tokens.padding.large
                                verticalPadding: Tokens.padding.small
                                disabled: pass.text.length === 0
                                text: Tr.tr("Install")
                                onClicked: companions.doInstall()
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: Companions.installError.length > 0 && !companions.installing && !companions.installed
                        text: Companions.installError
                        color: Colours.palette.m3error
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    // ── 4 · Ready ─────────────────────────────────────────────────────────────────────────
    Component {
        id: donePage

        ColumnLayout {
            spacing: Tokens.spacing.large

            Item {
                Layout.fillHeight: true
            }

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "check_circle"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.extraLarge
                fill: 1
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("You are all set")
                font: Tokens.font.headline.medium
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 520
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: Tr.tr("Open Nexus whenever you want to change something. This guide is in Nexus → About.")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.large
            }

            IconTextButton {
                Layout.alignment: Qt.AlignHCenter
                isRound: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.large
                verticalPadding: Tokens.padding.medium
                icon: "tune"
                text: Tr.tr("Open Nexus")
                onClicked: WindowFactory.openPage("activities")
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
