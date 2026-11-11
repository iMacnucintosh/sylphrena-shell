pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Sylphrena.Components
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// Add or edit a VPN provider. editingVpnIndex (-1 = add) is read from NexusState.
// A provider is either a command provider (built-in names or custom connect/disconnect commands) or
// a connection of a provider type contributed by an extension (VPN.providerTypes, e.g. FortiClient):
// then the extension's editor fills `options` and keeps its own secrets.
PageBase {
    id: root

    readonly property int editIndex: nState.editingVpnIndex
    readonly property bool editing: editIndex >= 0
    readonly property var existing: editing ? (VPN.providers[editIndex] ?? null) : null

    // "" = command provider, else the id of a provider type (`ext:<extension id>`)
    property string selectedType: ""
    readonly property var typeEntry: selectedType ? (VPN.providerTypes.find(t => t.id === selectedType) ?? null) : null
    readonly property var extEntry: typeEntry ? Extensions.vpnEditorEntry(selectedType) : null
    // Choosing the type only makes sense for a new provider
    readonly property bool showTypes: !editing && VPN.providerTypes.length > 0
    property string formError: ""

    function splitCmd(arr: var): string {
        return arr?.join(" ") ?? "";
    }

    function joinCmd(str: string): var {
        const t = str.trim();
        return t.length > 0 ? t.split(/\s+/) : [];
    }

    function arrEq(a: var, b: var): bool {
        return a.length === b.length && a.every((x, i) => x === b[i]);
    }

    function submit(): void {
        if (root.selectedType)
            root.submitTyped();
        else
            root.submitCommands();
    }

    function submitTyped(): void {
        const editor = slot.item;
        const name = connNameField.text.trim();
        if (name.length === 0) {
            connNameField.isError = true;
            connNameField.forceActiveFocus();
            return;
        }
        if (!editor)
            return;
        const err = editor.validate?.() ?? "";
        root.formError = err;
        if (err)
            return;

        const data = {
            name: name,
            displayName: name,
            type: root.selectedType,
            options: editor.collectOptions?.() ?? {}
        };
        let id;
        if (editing) {
            id = existing.id;
            VPN.updateProvider(editIndex, data);
        } else {
            id = VPN.addProvider(data);
        }
        // Secrets (password, …) stay with the extension, outside shell.json
        editor.commit?.(id);
        nState.closeSubPage();
    }

    function submitCommands(): void {
        const name = nameField.text.trim();
        if (name.length === 0) {
            nameField.isError = true;
            nameField.forceActiveFocus();
            return;
        }

        const data = {
            name: name,
            displayName: displayField.text.trim() || name,
            interface: interfaceField.text.trim(),
            connectCmd: joinCmd(connectField.text),
            disconnectCmd: joinCmd(disconnectField.text)
        };

        if (editing) {
            const needsReload = existing.id === VPN.selectedProvider && VPN.connected && (existing.name !== name || existing.interface !== data.interface || !arrEq(existing.connectCmd, data.connectCmd) || !arrEq(existing.disconnectCmd, data.disconnectCmd));
            if (needsReload)
                VPN.disconnect();
            VPN.updateProvider(editIndex, data);
            if (needsReload) {
                if (!VPN.connecting && !VPN.disconnecting) {
                    VPN.connect();
                } else if (VPN.disconnecting) {
                    let onConnChanged = () => {
                        if (onConnChanged && !VPN.disconnecting) {
                            VPN.disconnectingChanged.disconnect(onConnChanged);
                            onConnChanged = null;
                            if (!VPN.connected)
                                VPN.connect();
                        }
                    };
                    VPN.disconnectingChanged.connect(onConnChanged);
                }
            }
        } else {
            VPN.addProvider(data);
        }

        nState.closeSubPage();
    }

    title: editing ? Tr.tr("Edit VPN provider") : Tr.tr("Add VPN provider")
    isSubPage: true

    Component.onCompleted: {
        if (!existing && nState.newVpnType && VPN.providerTypes.some(t => t.id === nState.newVpnType))
            root.selectedType = nState.newVpnType;
        if (existing) {
            root.selectedType = existing.type ?? "";
            nameField.text = existing.name;
            displayField.text = existing.displayName;
            interfaceField.text = existing.interface;
            connectField.text = splitCmd(existing.connectCmd);
            disconnectField.text = splitCmd(existing.disconnectCmd);
            connNameField.text = existing.displayName || existing.name;
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        // ---- Type ----------------------------------------------------------
        ButtonRow {
            Layout.fillWidth: true
            visible: root.showTypes
            spacing: Tokens.spacing.small

            TextButton {
                fillWidth: true
                isToggle: true
                isRound: true
                type: TextButton.Tonal
                verticalPadding: Tokens.padding.medium
                checked: root.selectedType === ""
                text: Tr.tr("Commands")
                onClicked: {
                    root.selectedType = "";
                    root.formError = "";
                }
            }

            Repeater {
                model: VPN.providerTypes

                TextButton {
                    required property var modelData

                    fillWidth: true
                    isToggle: true
                    isRound: true
                    type: TextButton.Tonal
                    verticalPadding: Tokens.padding.medium
                    checked: root.selectedType === modelData.id
                    text: modelData.displayName
                    onClicked: {
                        root.selectedType = modelData.id;
                        root.formError = "";
                    }
                }
            }
        }

        // ---- Connection of an extension's provider type --------------------
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.selectedType !== ""
            spacing: Tokens.spacing.large

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                visible: !root.extEntry
                text: Tr.tr("This provider type comes from an extension that is disabled. Enable it in Nexus → Complements to edit the connection.")
                color: Colours.palette.m3error
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            StyledTextField {
                id: connNameField

                Layout.fillWidth: true
                placeholderText: Tr.tr("Connection name")
                supportingText: Tr.tr("Shown in the list")
                errorText: Tr.tr("Provider name is required")
                leadingIcon: root.typeEntry?.icon ?? "vpn_key"
                inputMethodHints: Qt.ImhNoPredictiveText
            }

            ExtensionSlot {
                id: slot

                Layout.fillWidth: true
                visible: !!root.extEntry
                entry: root.extEntry
                props: ({
                        options: root.existing?.type ? (root.existing.options ?? {}) : {},
                        providerId: root.existing?.type ? root.existing.id : ""
                    })
            }
        }

        // ---- Command provider ------------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.selectedType === ""
            spacing: Tokens.spacing.large

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                // TRANSLATORS: the four names in brackets are provider identifiers, leave them untranslated
                text: Tr.tr("Built-in names (wireguard, warp, tailscale, netbird) auto-fill their commands. For others, provide the connect/disconnect commands.")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            StyledTextField {
                id: nameField

                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                placeholderText: Tr.tr("Provider name")
                leadingIcon: "vpn_key"
                // TRANSLATORS: id here means the provider identifier, e.g. wireguard
                supportingText: Tr.tr("Built-in id or a custom name")
                errorText: Tr.tr("Provider name is required")
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

                onAccepted: displayField.forceActiveFocus()
            }

            StyledTextField {
                id: displayField

                Layout.fillWidth: true
                placeholderText: Tr.tr("Display name")
                // TRANSLATORS: the name shown in the VPN provider list on the network page
                supportingText: Tr.tr("Shown in the list")
                leadingIcon: "label"
                inputMethodHints: Qt.ImhNoPredictiveText

                onAccepted: interfaceField.forceActiveFocus()
            }

            StyledTextField {
                id: interfaceField

                Layout.fillWidth: true
                placeholderText: Tr.trCtx("Interface", "network interface")
                leadingIcon: "lan"
                supportingText: Tr.tr("Network interface (for WireGuard / status checks)")
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

                onAccepted: connectField.forceActiveFocus()
            }

            SectionHeader {
                text: Tr.tr("Custom commands (optional)")
            }

            StyledTextField {
                id: connectField

                Layout.fillWidth: true
                placeholderText: Tr.tr("Connect command")
                leadingIcon: "play_arrow"
                supportingText: Tr.tr("Leave empty to use the built-in default")
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

                onAccepted: disconnectField.forceActiveFocus()
            }

            StyledTextField {
                id: disconnectField

                Layout.fillWidth: true
                placeholderText: Tr.tr("Disconnect command")
                leadingIcon: "stop"
                supportingText: Tr.tr("Leave empty to use the built-in default")
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

                onAccepted: root.submit()
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            visible: root.formError.length > 0
            text: root.formError
            color: Colours.palette.m3error
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: (root.editing ? Tokens.spacing.medium : Tokens.spacing.extraSmall) - parent.spacing
            spacing: Tokens.spacing.small

            IconTextButton {
                visible: root.editing
                isRound: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                inactiveColour: Colours.palette.m3errorContainer
                inactiveOnColour: Colours.palette.m3onErrorContainer
                iconLabel.fill: 1
                iconLabel.grade: 25
                icon: "delete_forever"
                text: Tr.tr("Delete")
                onClicked: {
                    const id = root.existing.id;
                    const t = VPN.typeOf(root.existing);
                    if (id === VPN.selectedProvider && VPN.connected)
                        VPN.disconnect();
                    VPN.deleteProvider(root.editIndex);
                    // The extension drops what it keeps for the connection (its secrets file, …)
                    t?.service?.forget?.(id);
                    root.nState.closeSubPage();
                }
            }

            Item {
                Layout.fillWidth: true
            }

            ButtonRow {
                spacing: parent.spacing

                TextButton {
                    isRound: true
                    shapeMorph: true
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    type: TextButton.Tonal
                    text: Tr.trCtx("Cancel", "button")
                    onClicked: root.nState.closeSubPage()
                }

                TextButton {
                    isRound: true
                    shapeMorph: true
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    text: root.editing ? Tr.trCtx("Save", "button") : Tr.trCtx("Add", "button")
                    disabled: root.selectedType ? (!connNameField.text.trim() || !root.extEntry) : !nameField.text.trim()
                    onClicked: root.submit()
                }
            }
        }
    }
}
