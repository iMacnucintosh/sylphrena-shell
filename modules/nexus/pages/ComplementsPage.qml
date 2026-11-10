pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root


    title: Tr.tr("Complements")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Available")
        }

        // Optional extensions of type "addon" (see services/Extensions.qml)
        Repeater {
            model: Extensions.discovered.filter(d => d.manifest.type === "addon")

            delegate: ExtensionCard {
                required property var modelData
                required property int index

                item: modelData
                first: index === 0
            }
        }
    }
}
