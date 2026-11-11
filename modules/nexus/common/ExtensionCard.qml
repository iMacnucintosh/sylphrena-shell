pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services

// One extension in a Nexus list: icon, name, what it is (the manifest description), enable switch and,
// when the extension contributes `settings`, an expandable area with its Settings.qml. Installing,
// updating and removing extensions is Things' job: here an extension is only turned on and off and
// configured. Nothing here is specific to a given extension: it all comes from the manifest.
ConnectedRect {
    id: root

    // { dir, manifest } as listed in Extensions.discovered
    required property var item

    readonly property var manifest: item.manifest
    readonly property bool active: Extensions.isEnabled(manifest.id)
    readonly property var service: active ? Extensions.service(manifest.id) : null
    readonly property bool hasSettings: !!manifest.contributes?.settings && active && !!service
    property bool settingsOpen: false

    // Its system pieces (a helper, a package) are not there: it cannot be enabled until Things installs them
    readonly property bool needsSystem: Extensions.hasSystem(manifest) && !Extensions.systemReady(manifest.id)
    // Why it is not running (e.g. it needs a newer Sylphrena), when that is the case
    readonly property string problem: Extensions.loaded.find(e => e.id === manifest.id)?.error || Extensions.incompatibility(manifest)

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

                // What the extension is: always the manifest description. Its live state is the
                // extension's own business (it shows it wherever it wants).
                StyledText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.manifest.description ? Tr.tr(root.manifest.description) : ""
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
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
                // Installing its system pieces comes first (in Things); turning it off is always possible
                disabled: !root.active && root.needsSystem
                checked: root.active
                onToggled: {
                    Extensions.setEnabled(root.manifest.id, checked);
                    root.settingsOpen = checked && !!root.manifest.contributes?.settings;
                }
            }
        }

        // It cannot run here: needs a newer Sylphrena, or its system pieces are missing
        RowLayout {
            Layout.fillWidth: true
            visible: root.problem.length > 0 || root.needsSystem
            spacing: Tokens.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                text: "warning"
                color: Colours.palette.m3error
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                Layout.fillWidth: true
                text: root.problem.length > 0 ? root.problem : Tr.tr("Its system components are missing: install the extension again from Things.")
                color: Colours.palette.m3error
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }

            TextButton {
                visible: root.needsSystem && root.problem.length === 0
                Layout.alignment: Qt.AlignVCenter
                isRound: true
                type: TextButton.Tonal
                horizontalPadding: Tokens.padding.large
                verticalPadding: Tokens.padding.small
                disabled: !Companions.isInstalled("things")
                text: Tr.tr("Open Things")
                onClicked: Companions.launch("things")
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
