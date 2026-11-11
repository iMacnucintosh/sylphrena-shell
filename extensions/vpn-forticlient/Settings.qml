import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.services

// Shown in the extension's card in Nexus → Complements
StyledText {
    required property var ext
    required property var service

    Layout.fillWidth: true
    text: Tr.tr("FortiClient VPN config: ~/.config/openfortivpn/config (Nexus → Network → edit). Scripts: ~/.local/share/sylphrena/vpn-forticlient/")
    color: Colours.palette.m3outline
    font: Tokens.font.label.small
    wrapMode: Text.Wrap
}
