pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    required property PopoutState popouts

    width: Math.max(320, Tokens.sizes.bar.networkWidth)
    spacing: Tokens.spacing.small

    function startConnect(): void {
        FortiVpn.requestOtp();
        root.popouts.currentName = "vpnOtp";
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.medium
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("VPN FortiClient")
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        IconButton {
            icon: "settings"
            type: IconButton.Text
            isRound: true
            onClicked: {
                FortiVpn.reloadConfig();
                root.popouts.currentName = "vpnSettings";
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: FortiVpn.connected ? "verified_user" : "remove_moderator"
            fill: FortiVpn.connected ? 1 : 0
            color: FortiVpn.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: FortiVpn.statusText
                color: Colours.palette.m3onSurface
                font: Tokens.font.body.medium
            }

            StyledText {
                visible: FortiVpn.connected && FortiVpn.vpnIp.length > 0
                text: FortiVpn.vpnIp
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.mono.small
            }
        }
    }

    TextButton {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        Layout.rightMargin: Tokens.padding.extraSmall
        Layout.minimumHeight: Tokens.font.body.medium.pointSize + Tokens.padding.medium * 2
        inactiveColour: FortiVpn.connected ? Colours.palette.m3errorContainer : Colours.palette.m3primary
        inactiveOnColour: FortiVpn.connected ? Colours.palette.m3onErrorContainer : Colours.palette.m3onPrimary
        text: FortiVpn.busy ? FortiVpn.statusText : (FortiVpn.connected ? Tr.tr("Disconnect") : Tr.tr("Connect"))
        enabled: !FortiVpn.busy

        onClicked: {
            if (FortiVpn.connected)
                FortiVpn.disconnect();
            else
                root.startConnect();
        }
    }
}
