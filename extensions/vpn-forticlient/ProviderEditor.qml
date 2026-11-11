pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Sylphrena.Components
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services

// Editor of the FortiClient connection (~/.config/openfortivpn/config), shown in Nexus → Network
// when editing this extension's VPN provider (manifest `vpnProvider.editor`).
ColumnLayout {
    id: root

    // Injected by the base: the extension and its service (see services/Extensions.qml)
    required property var ext
    required property var service
    // Closes the page that hosts the editor (set by the base)
    property var close: () => {}

    property bool showPassword: false

    spacing: Tokens.spacing.large

    function save(): void {
        root.service.cfgHost = hostField.text;
        root.service.cfgPort = portField.text;
        root.service.cfgUsername = userField.text;
        root.service.cfgPassword = passField.text;
        root.service.cfgRealm = realmField.text;
        if (root.service.saveConfig())
            root.close();
    }

    Component.onCompleted: {
        root.service.reloadConfig();
        Qt.callLater(() => {
            hostField.text = root.service.cfgHost;
            portField.text = root.service.cfgPort;
            userField.text = root.service.cfgUsername;
            passField.text = root.service.cfgPassword;
            realmField.text = root.service.cfgRealm;
        });
    }

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        text: Tr.tr("Stored in ~/.config/openfortivpn/config")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    ColumnLayout {
        Layout.fillWidth: true
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
        visible: !!root.service.configError
        text: root.service.configError
        color: Colours.palette.m3error
        font: Tokens.font.label.small
        wrapMode: Text.WordWrap
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.medium - root.spacing
        spacing: Tokens.spacing.small

        Item {
            Layout.fillWidth: true
        }

        ButtonRow {
            spacing: parent.spacing

            TextButton {
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                type: TextButton.Tonal
                text: Tr.trCtx("Cancel", "button")
                onClicked: root.close()
            }

            TextButton {
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                text: Tr.trCtx("Save", "button")
                onClicked: root.save()
            }
        }
    }
}
