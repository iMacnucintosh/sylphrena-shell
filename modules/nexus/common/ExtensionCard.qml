pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services

// One extension in a Nexus list: icon, name, status line, enable switch and, when the extension
// contributes `settings`, an expandable area with its Settings.qml. Nothing here is specific to a
// given extension: it all comes from the manifest and the extension's service.
ConnectedRect {
    id: root

    // { dir, manifest } as listed in Extensions.discovered
    required property var item

    readonly property var manifest: item.manifest
    readonly property bool active: Extensions.isEnabled(manifest.id)
    readonly property var service: active ? Extensions.service(manifest.id) : null
    readonly property bool hasSettings: !!manifest.contributes?.settings && active && !!service
    property bool settingsOpen: false

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + Tokens.padding.medium * 2

    ColumnLayout {
        id: col

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: root.manifest.icon ?? "extension"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr(root.manifest.name)
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        const desc = root.manifest.description ? Tr.tr(root.manifest.description) : "";
                        if (!root.active)
                            return root.manifest.offNote ? Tr.tr(root.manifest.offNote) : desc;
                        return root.service?.statusText || desc;
                    }
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }
            }

            IconButton {
                visible: root.hasSettings
                isRound: true
                type: IconButton.Text
                icon: root.settingsOpen ? "expand_less" : "expand_more"
                padding: Tokens.padding.small
                Layout.alignment: Qt.AlignVCenter
                onClicked: root.settingsOpen = !root.settingsOpen
            }

            StyledSwitch {
                Layout.alignment: Qt.AlignVCenter
                checked: root.active
                onToggled: {
                    Extensions.setEnabled(root.manifest.id, checked);
                    root.settingsOpen = checked && !!root.manifest.contributes?.settings;
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            active: root.hasSettings && root.settingsOpen
            visible: active
            sourceComponent: ExtensionSlot {
                entry: Extensions.settingsEntry(root.manifest.id)
            }
        }
    }
}
