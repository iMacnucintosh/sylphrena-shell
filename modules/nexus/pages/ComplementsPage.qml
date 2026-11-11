pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.components.filedialog
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

        // ---- Install from a zip (into ~/.local/share/sylphrena/extensions) ------
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            spacing: Tokens.spacing.medium

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                text: Extensions.zipError.length > 0 ? Extensions.zipError : Tr.tr("Extensions are .zip packages with a manifest.json. Installing one again updates it.")
                color: Extensions.zipError.length > 0 ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            IconTextButton {
                Layout.alignment: Qt.AlignVCenter
                isRound: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                disabled: Extensions.zipBusy || zipPicker.busy
                icon: "upload_file"
                text: Extensions.zipBusy ? Tr.tr("Installing…") : Tr.tr("Install from zip")
                onClicked: zipPicker.open()
            }
        }

        FileDialog {
            id: zipPicker

            title: Tr.tr("Select an extension package")
            filterLabel: Tr.tr("Extension packages (.zip)")
            filters: ["zip"]
            onAccepted: path => Extensions.installZip(path)
        }
    }
}
