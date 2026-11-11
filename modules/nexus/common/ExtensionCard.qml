pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services

// One extension in a Nexus list: icon, name, status line, enable switch and, when the extension
// contributes `settings`, an expandable area with its Settings.qml. An extension that declares
// `system` pieces (root helper, package, …) shows their state and an Install / Update / Remove
// button that asks for the password inline; it can be enabled only once installed. Nothing here is
// specific to a given extension: it all comes from the manifest and the extension's service.
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
    // "install" | "uninstall" while the password field is shown
    property string pendingAction: ""

    function confirmSystem(): void {
        if (passField.text.length === 0)
            return;
        Extensions.runSystem(root.manifest.id, root.pendingAction, passField.text);
        passField.text = "";
        root.pendingAction = "";
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
                // Installing comes first; turning it off is always possible
                disabled: !root.active && root.hasSystem && !Extensions.systemReady(root.manifest.id)
                checked: root.active
                onToggled: {
                    Extensions.setEnabled(root.manifest.id, checked);
                    root.settingsOpen = checked && !!root.manifest.contributes?.settings;
                }
            }
        }

        // ---- System pieces ----------------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.hasSystem
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.systemState === "installed" ? "verified" : root.systemState === "outdated" ? "update" : "install_desktop"
                    color: root.systemState === "installed" ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: {
                            if (root.systemBusy)
                                return Extensions.systemAction === "uninstall" ? Tr.tr("Removing system components…") : Tr.tr("Installing system components…");
                            switch (root.systemState) {
                            case "installed":
                                return Tr.tr("System components installed");
                            case "outdated":
                                return Tr.tr("A newer version of its system components is available");
                            case "missing":
                                return Tr.tr("Needs system components (asks for your password once)");
                            }
                            return Tr.tr("Checking system components…");
                        }
                        font: Tokens.font.label.medium
                        wrapMode: Text.WordWrap
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text.length > 0 && root.systemState !== "installed"
                        text: root.manifest.system?.description ? Tr.tr(root.manifest.system.description) : ""
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                    }
                }

                TextButton {
                    Layout.alignment: Qt.AlignVCenter
                    visible: !root.systemBusy && root.pendingAction === "" && root.systemState !== ""
                    isRound: true
                    type: root.systemState === "installed" ? TextButton.Text : TextButton.Filled
                    horizontalPadding: Tokens.padding.large
                    verticalPadding: Tokens.padding.small
                    text: root.systemState === "installed" ? Tr.tr("Remove") : root.systemState === "outdated" ? Tr.tr("Update") : Tr.tr("Install")
                    onClicked: {
                        root.pendingAction = root.systemState === "installed" ? "uninstall" : "install";
                        Qt.callLater(() => passField.forceActiveFocus());
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.pendingAction !== ""
                spacing: Tokens.spacing.small

                StyledTextField {
                    id: passField

                    Layout.fillWidth: true
                    placeholderText: Tr.tr("Your password (sudo)")
                    leadingIcon: "key"
                    echoMode: TextInput.Password
                    onAccepted: root.confirmSystem()
                    Keys.onEscapePressed: {
                        passField.text = "";
                        root.pendingAction = "";
                    }
                }

                TextButton {
                    isRound: true
                    type: TextButton.Tonal
                    horizontalPadding: Tokens.padding.large
                    verticalPadding: Tokens.padding.small
                    text: Tr.trCtx("Cancel", "button")
                    onClicked: {
                        passField.text = "";
                        root.pendingAction = "";
                    }
                }

                TextButton {
                    isRound: true
                    horizontalPadding: Tokens.padding.large
                    verticalPadding: Tokens.padding.small
                    disabled: passField.text.length === 0
                    text: root.pendingAction === "uninstall" ? Tr.tr("Remove") : Tr.tr("Install")
                    onClicked: root.confirmSystem()
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
