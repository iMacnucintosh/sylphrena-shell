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

    title: Tr.tr("Extensions")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // ---- Install from a zip (into ~/.local/share/sylphrena/extensions) ------
        ConnectedRect {
            id: installRow

            readonly property bool busy: Extensions.zipBusy || zipPicker.busy || Extensions.systemBusyId !== ""

            Layout.fillWidth: true
            first: true
            last: !Extensions.zipPending
            implicitHeight: installLayout.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: installLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    Layout.alignment: Qt.AlignVCenter
                    text: installRow.busy ? "hourglass_top" : "upload_file"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                    fill: 1
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: installRow.busy ? Tr.tr("Installing…") : Tr.tr("Install from zip")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    // Only when something went wrong
                    StyledText {
                        Layout.fillWidth: true
                        visible: Extensions.zipError.length > 0
                        text: Extensions.zipError
                        color: Colours.palette.m3error
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                    }
                }

                IconTextButton {
                    Layout.alignment: Qt.AlignVCenter
                    isRound: true
                    horizontalPadding: Tokens.padding.large
                    verticalPadding: Tokens.padding.small
                    disabled: installRow.busy || !!Extensions.zipPending
                    icon: "folder_open"
                    text: Tr.tr("Browse")
                    onClicked: zipPicker.open()
                }
            }
        }

        // The extension in the zip installs something as administrator: password first, or nothing
        ConnectedRect {
            Layout.fillWidth: true
            visible: !!Extensions.zipPending
            last: true
            implicitHeight: pendingCol.implicitHeight + Tokens.padding.medium * 2

            ColumnLayout {
                id: pendingCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            // TRANSLATORS: %1 = extension name
                            text: Tr.tr("Install %1?").arg(Extensions.zipPending ? Tr.tr(Extensions.zipPending.name) : "")
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: Extensions.zipPending?.description ? Tr.tr(Extensions.zipPending.description) : ""
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            wrapMode: Text.WordWrap
                        }
                    }

                    TextButton {
                        id: cancelBtn

                        Layout.alignment: Qt.AlignVCenter
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

                        Layout.alignment: Qt.AlignVCenter
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

                StyledTextField {
                    id: zipPass

                    Layout.fillWidth: true
                    placeholderText: Tr.tr("Your password (sudo)")
                    leadingIcon: "key"
                    echoMode: TextInput.Password
                    onAccepted: installBtn.clicked()
                    Keys.onEscapePressed: cancelBtn.clicked()
                }
            }
        }

        // ---- Installed ---------------------------------------------------------
        SectionHeader {
            text: Tr.tr("Installed")
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

        FileDialog {
            id: zipPicker

            title: Tr.tr("Select an extension package")
            filterLabel: Tr.tr("Extension packages (.zip)")
            filters: ["zip"]
            onAccepted: path => Extensions.installZip(path)
        }
    }
}
