pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// The extensions installed for the shell: turn them on and off, configure them. Finding, installing,
// updating and removing them is done in Things (the row at the top opens it).
PageBase {
    id: root

    title: Tr.tr("Extensions")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // ---- Find more in Things (the app that manages the catalog) ----------------------
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: thingsRow.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: thingsRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    Layout.alignment: Qt.AlignVCenter
                    text: Companions.find("things").icon
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                    fill: 1
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Find more in Things")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: Companions.checked && !Companions.isInstalled("things")
                        text: Tr.tr("Things is not installed")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }
                }

                IconTextButton {
                    Layout.alignment: Qt.AlignVCenter
                    isRound: true
                    horizontalPadding: Tokens.padding.large
                    verticalPadding: Tokens.padding.small
                    disabled: !Companions.isInstalled("things")
                    icon: "open_in_new"
                    text: Tr.tr("Open Things")
                    onClicked: Companions.launch("things")
                }
            }
        }

        // ---- Installed ---------------------------------------------------------------------
        SectionHeader {
            text: Tr.tr("Installed")
        }

        // Extensions of type "addon" (see services/Extensions.qml)
        Repeater {
            id: addons

            model: Extensions.discovered.filter(d => d.manifest.type === "addon")

            delegate: ExtensionCard {
                required property var modelData
                required property int index

                item: modelData
                first: index === 0
                last: index === addons.count - 1
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            Layout.leftMargin: Tokens.padding.small
            visible: addons.count === 0
            text: Tr.tr("No extensions installed yet.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
        }
    }
}
