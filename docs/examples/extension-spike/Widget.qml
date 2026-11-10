import QtQuick
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.services
import "parts"

// Spike widget: gets the extension's service and context from whoever places it
Item {
    id: root

    required property var ext
    required property var service

    implicitHeight: 220

    Column {
        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.ext.manifest.icon
            color: Colours.palette.m3primary
        }

        Sibling {
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Nested {
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // A shader shipped by the extension would go here (see docs/PLAN-MODULAR.md §5.3):
        //   ShaderEffect { fragmentShader: Qt.resolvedUrl("water.frag.qsb") }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: `${root.ext.manifest.name} · ${Tr.tr("Tasks")} · ticks ${root.service?.ticks ?? "?"}`
        }
    }
}
