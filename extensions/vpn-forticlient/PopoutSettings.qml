pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    // Injected by the base: the extension and its service (see services/Extensions.qml)
    required property var ext
    required property var service

    required property var popouts

    readonly property bool shouldBeVisible: root.popouts.currentName === "vpnSettings"
    property bool showPassword: false

    width: Math.max(380, Tokens.sizes.bar.networkWidth + Tokens.padding.large)
    spacing: Tokens.spacing.medium

    function closeDialog(): void {
        if (root.popouts.currentName === "vpnSettings")
            root.popouts.currentName = "vpn";
    }

    function save(): void {
        root.service.cfgHost = hostField.text;
        root.service.cfgPort = portField.text;
        root.service.cfgUsername = userField.text;
        root.service.cfgPassword = passField.text;
        root.service.cfgRealm = realmField.text;
        if (root.service.saveConfig())
            root.closeDialog();
    }

    visible: shouldBeVisible
    focus: shouldBeVisible

    Keys.onEscapePressed: closeDialog()

    onShouldBeVisibleChanged: {
        if (shouldBeVisible) {
            root.service.reloadConfig();
            Qt.callLater(() => {
                hostField.text = root.service.cfgHost;
                portField.text = root.service.cfgPort;
                userField.text = root.service.cfgUsername;
                passField.text = root.service.cfgPassword;
                realmField.text = root.service.cfgRealm;
                root.showPassword = false;
                hostField.forceActiveFocus();
            });
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.medium
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        IconButton {
            icon: "arrow_back"
            type: IconButton.Text
            isRound: true
            onClicked: root.closeDialog()
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("VPN settings")
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Stored in ~/.config/openfortivpn/config")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        Layout.topMargin: Tokens.spacing.small
        spacing: Tokens.spacing.large

        StyledTextField {
            id: hostField

            Layout.fillWidth: true
            verticalPadding: Tokens.padding.small
            placeholderText: Tr.trCtx("Host", "vpn server hostname")
            leadingIcon: "dns"
            text: root.service.cfgHost
            onAccepted: portField.forceActiveFocus()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StyledTextField {
                id: portField

                Layout.preferredWidth: Math.round(root.width * 0.32)
                Layout.minimumWidth: Tokens.sizes.nexus.smallTextFieldWidth
                verticalPadding: Tokens.padding.small
                placeholderText: Tr.trCtx("Port", "vpn server port")
                leadingIcon: "tag"
                text: root.service.cfgPort
                inputMethodHints: Qt.ImhDigitsOnly
                onAccepted: realmField.forceActiveFocus()
            }

            StyledTextField {
                id: realmField

                Layout.fillWidth: true
                verticalPadding: Tokens.padding.small
                placeholderText: Tr.trCtx("Realm", "vpn authentication realm")
                leadingIcon: "domain"
                text: root.service.cfgRealm
                onAccepted: userField.forceActiveFocus()
            }
        }

        StyledTextField {
            id: userField

            Layout.fillWidth: true
            verticalPadding: Tokens.padding.small
            placeholderText: Tr.trCtx("Username", "vpn username")
            leadingIcon: "person"
            text: root.service.cfgUsername
            onAccepted: passField.forceActiveFocus()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledTextField {
                id: passField

                Layout.fillWidth: true
                verticalPadding: Tokens.padding.small
                placeholderText: Tr.trCtx("Password", "vpn password")
                leadingIcon: "key"
                text: root.service.cfgPassword
                echoMode: root.showPassword ? T.TextField.Normal : T.TextField.Password
                onAccepted: root.save()
            }

            IconButton {
                Layout.alignment: Qt.AlignVCenter
                icon: root.showPassword ? "visibility_off" : "visibility"
                type: IconButton.Text
                isRound: true
                onClicked: root.showPassword = !root.showPassword
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        visible: !!root.service.configError
        text: root.service.configError
        color: Colours.palette.m3error
        font: Tokens.font.label.small
        wrapMode: Text.WordWrap
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.medium

        TextButton {
            Layout.fillWidth: true
            Layout.minimumHeight: Tokens.font.body.medium.pointSize + Tokens.padding.medium * 2
            inactiveColour: Colours.palette.m3secondaryContainer
            inactiveOnColour: Colours.palette.m3onSecondaryContainer
            text: Tr.trCtx("Cancel", "button")
            onClicked: root.closeDialog()
        }

        TextButton {
            Layout.fillWidth: true
            Layout.minimumHeight: Tokens.font.body.medium.pointSize + Tokens.padding.medium * 2
            inactiveColour: Colours.palette.m3primary
            inactiveOnColour: Colours.palette.m3onPrimary
            text: Tr.trCtx("Save", "button")
            onClicked: root.save()
        }
    }
}
