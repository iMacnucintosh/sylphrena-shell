import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.services

// Shown in the extension's card in Nexus → Complements
StyledText {
    id: root

    required property var ext
    required property var service

    Layout.fillWidth: true
    text: root.service.helperInstalled ? Tr.tr("Connections: Nexus → Network → Add provider → FortiClient.") : Tr.tr("The FortiClient helper is not installed: install the extension in Nexus → Complements")
    color: root.service.helperInstalled ? Colours.palette.m3outline : Colours.palette.m3error
    font: Tokens.font.label.small
    wrapMode: Text.Wrap
}
