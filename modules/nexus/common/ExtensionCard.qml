pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services

// One extension in a Nexus list: icon, name, status line, enable switch and, when the extension
// contributes `settings`, an expandable area with its Settings.qml. Extensions installed from a zip
// can be deleted (asking for the password when they installed something as root, which goes with
// them). If that root part is missing or out of date (a failed install), "Installation incomplete"
// offers to complete it. Nothing here is specific to a given extension: it all comes from the
// manifest and the extension's service.
ConnectedRect {
    id: root

    // { dir, manifest } as listed in Extensions.discovered
    required property var item

    readonly property var manifest: item.manifest
    readonly property bool active: Extensions.isEnabled(manifest.id)
    readonly property var service: active ? Extensions.service(manifest.id) : null
    readonly property bool hasSettings: !!manifest.contributes?.settings && active && !!service
    property bool settingsOpen: false

    readonly property bool hasSystem: Extensions.hasSystem(manifest)
    // "installed" | "outdated" | "missing" ("" while checking)
    readonly property string systemState: Extensions.systemState[manifest.id] ?? ""
    readonly property bool systemBusy: Extensions.systemBusyId === manifest.id
    readonly property string systemError: Extensions.systemErrorId === manifest.id ? Extensions.systemError : ""
    // The root part is missing or older than the extension's: offer to complete the install
    readonly property bool incomplete: hasSystem && ["missing", "outdated"].includes(systemState)
    // Installed by the user (from a zip): it can be deleted from here
    readonly property bool removable: Extensions.isUserInstalled(manifest.id)
    // "" | "remove" | "complete": what the confirmation row below is for
    property string pendingAction: ""
    readonly property bool needsPassword: root.pendingAction === "complete" || (root.pendingAction === "remove" && Extensions.needsSystemRemoval(root.manifest.id))

    function cancelAction(): void {
        passField.text = "";
        root.pendingAction = "";
    }

    function confirmAction(): void {
        if (root.needsPassword && passField.text.length === 0)
            return;
        if (root.pendingAction === "remove")
            Extensions.removeExtension(root.manifest.id, passField.text);
        else if (root.pendingAction === "complete")
            Extensions.runSystem(root.manifest.id, "install", passField.text);
        root.cancelAction();
    }

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

            IconButton {
                visible: root.removable && root.pendingAction === ""
                isRound: true
                type: IconButton.Text
                icon: "delete"
                padding: Tokens.padding.small
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    root.pendingAction = "remove";
                    Qt.callLater(() => passField.forceActiveFocus());
                }
            }

            StyledSwitch {
                Layout.alignment: Qt.AlignVCenter
                // Installing comes first; turning it off is always possible
                disabled: !root.active && root.hasSystem && !Extensions.systemReady(root.manifest.id)
                checked: root.active
                onToggled: {
                    Extensions.setEnabled(root.manifest.id, checked);
                    root.settingsOpen = checked && !!root.manifest.contributes?.settings;
                }
            }
        }

        // ---- Installation incomplete (its root part failed or is out of date) ----
        RowLayout {
            Layout.fillWidth: true
            visible: root.incomplete || root.systemBusy
            spacing: Tokens.spacing.medium

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                text: "warning"
                color: Colours.palette.m3error
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                Layout.fillWidth: true
                text: root.systemBusy ? (Extensions.systemAction === "uninstall" ? Tr.tr("Removing…") : Tr.tr("Installing…")) : Tr.tr("Installation incomplete: it needs your password to finish")
                font: Tokens.font.label.medium
                wrapMode: Text.WordWrap
            }

            TextButton {
                Layout.alignment: Qt.AlignVCenter
                visible: !root.systemBusy && root.pendingAction === ""
                isRound: true
                horizontalPadding: Tokens.padding.large
                verticalPadding: Tokens.padding.small
                text: Tr.tr("Complete")
                onClicked: {
                    root.pendingAction = "complete";
                    Qt.callLater(() => passField.forceActiveFocus());
                }
            }
        }

        // ---- Confirmation (delete / complete): question and buttons, the password below when needed --
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.pendingAction !== ""
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: root.pendingAction === "remove" ? Tr.tr("Delete this extension?") : Tr.tr("Finish the installation?")
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                TextButton {
                    isRound: true
                    type: TextButton.Tonal
                    horizontalPadding: Tokens.padding.large
                    verticalPadding: Tokens.padding.small
                    text: Tr.trCtx("Cancel", "button")
                    onClicked: root.cancelAction()
                }

                TextButton {
                    isRound: true
                    horizontalPadding: Tokens.padding.large
                    verticalPadding: Tokens.padding.small
                    disabled: Extensions.zipBusy || (root.needsPassword && passField.text.length === 0)
                    inactiveColour: root.pendingAction === "remove" ? Colours.palette.m3error : Colours.palette.m3primary
                    inactiveOnColour: root.pendingAction === "remove" ? Colours.palette.m3onError : Colours.palette.m3onPrimary
                    text: root.pendingAction === "remove" ? Tr.tr("Delete") : Tr.tr("Complete")
                    onClicked: root.confirmAction()
                }
            }

            StyledTextField {
                id: passField

                Layout.fillWidth: true
                visible: root.needsPassword
                placeholderText: Tr.tr("Password")
                leadingIcon: "key"
                echoMode: TextInput.Password
                onAccepted: root.confirmAction()
                Keys.onEscapePressed: root.cancelAction()
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.systemError.length > 0
            text: root.systemError
            color: Colours.palette.m3error
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        Loader {
            Layout.fillWidth: true
            active: root.hasSettings && root.settingsOpen && root.pendingAction === ""
            visible: active
            sourceComponent: ExtensionSlot {
                entry: Extensions.settingsEntry(root.manifest.id)
            }
        }
    }
}
