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
                disabled: Extensions.zipBusy || zipPicker.busy || !!Extensions.zipPending || Extensions.systemBusyId !== ""
                icon: "upload_file"
                text: Extensions.zipBusy ? Tr.tr("Installing…") : Tr.tr("Install from zip")
                onClicked: zipPicker.open()
            }
        }

        // The extension in the zip installs something as administrator: password first, or nothing
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            visible: !!Extensions.zipPending
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                // TRANSLATORS: %1 = extension name
                text: Tr.tr("%1 needs administrator rights to install").arg(Extensions.zipPending ? Tr.tr(Extensions.zipPending.name) : "")
                font: Tokens.font.body.medium
                wrapMode: Text.WordWrap
            }

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                visible: text.length > 0
                text: Extensions.zipPending?.description ? Tr.tr(Extensions.zipPending.description) : ""
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledTextField {
                    id: zipPass

                    Layout.fillWidth: true
                    placeholderText: Tr.tr("Your password (sudo)")
                    leadingIcon: "key"
                    echoMode: TextInput.Password
                    onAccepted: installBtn.clicked()
                    Keys.onEscapePressed: cancelBtn.clicked()
                }

                TextButton {
                    id: cancelBtn

                    isRound: true
                    type: TextButton.Tonal
                    horizontalPadding: Tokens.padding.large
                    verticalPadding: Tokens.padding.small
                    text: Tr.trCtx("Cancel", "button")
                    onClicked: {
                        zipPass.text = "";
                        Extensions.cancelZip();
                    }
                }

                TextButton {
                    id: installBtn

                    isRound: true
                    horizontalPadding: Tokens.padding.large
                    verticalPadding: Tokens.padding.small
                    disabled: zipPass.text.length === 0 || Extensions.zipBusy
                    text: Tr.tr("Install")
                    onClicked: {
                        if (zipPass.text.length === 0)
                            return;
                        Extensions.confirmZip(zipPass.text);
                        zipPass.text = "";
                    }
                }
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
