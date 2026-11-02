pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Sylphrena
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.filedialog
import qs.services
import qs.utils
import qs.modules.drawers
import qs.modules.launcher.services

Item {
    id: root

    property DesktopEntry entry
    property bool open

    readonly property bool shouldShow: open && !!entry
    // Only the launcher drawer should claim Apps.editingDesktop (keeps the
    // drawer open / expands its hit region). Nexus hosts its own copy.
    readonly property bool inLauncherDrawer: !!(QsWindow.window as ContentWindow)

    signal closed

    function show(e: DesktopEntry): void {
        entry = e;
        nameField.text = e?.name ?? "";
        commentField.text = e?.comment ?? "";
        genericField.text = e?.genericName ?? "";
        iconField.text = e?.icon ?? "";
        execField.text = e?.execString ?? "";
        categoriesField.text = Apps.formatDesktopList(e?.categories);
        keywordsField.text = Apps.formatDesktopList(e?.keywords);
        startupField.text = e?.startupClass ?? "";
        pathField.text = e?.workingDirectory ?? "";
        terminalSwitch.checked = !!(e?.runInTerminal);
        open = true;
        if (root.inLauncherDrawer)
            Apps.editingDesktop = true;
        Qt.callLater(() => nameField.forceActiveFocus());
    }

    function close(): void {
        open = false;
        if (Apps.editingDesktop)
            Apps.editingDesktop = false;
        closed();
    }

    function save(): void {
        if (!entry)
            return;
        const ok = Apps.saveDesktopMetadata(entry.id, {
            name: nameField.text.trim(),
            comment: commentField.text.trim(),
            genericName: genericField.text.trim(),
            icon: iconField.text.trim(),
            exec: execField.text.trim(),
            categories: categoriesField.text.trim(),
            keywords: keywordsField.text.trim(),
            startupClass: startupField.text.trim(),
            workingDirectory: pathField.text.trim(),
            terminal: terminalSwitch.checked
        });
        if (!ok)
            console.warn(`DesktopEditDialog: failed to save ${entry.id}`);
        root.close();
    }

    function startIconBrowse(): void {
        iconPicker.open();
    }

    // Fill the drawer interaction area (or Nexus window) so the modal covers it
    parent: {
        const win = QsWindow.window;
        const contentWin = win as ContentWindow;
        return contentWin ? contentWin.interactionWrapper : (win as QsWindow)?.contentItem;
    }
    anchors.fill: parent
    visible: shouldShow
    z: 2000
    enabled: shouldShow

    MouseArea {
        anchors.fill: parent
        onClicked: event => {
            const p = mapToItem(card, event.x, event.y);
            if (p.x < 0 || p.y < 0 || p.x > card.width || p.y > card.height)
                root.close();
        }

        StyledRect {
            anchors.fill: parent
            color: Qt.alpha(Colours.palette.m3scrim, 0.55)
        }
    }

    Elevation {
        id: card

        anchors.centerIn: parent
        width: Math.min(parent.width - Tokens.padding.large * 2, 480)
        height: Math.min(parent.height - Tokens.padding.large * 2, panel.implicitHeight)
        radius: Tokens.rounding.extraLarge
        level: 3

        Behavior on height {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        StyledRect {
            id: panel

            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3surfaceContainerHigh
            implicitHeight: formShell.implicitHeight + Tokens.padding.large * 2
            clip: true

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: formShell

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                StyledText {
                    text: Tr.tr("Edit application")
                    font: Tokens.font.title.small
                    color: Colours.palette.m3onSurface
                }

                Flickable {
                    id: formFlick

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(formCol.implicitHeight, Math.max(280, (root.height || 800) * 0.55))
                    contentWidth: width
                    contentHeight: formCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick

                    ColumnLayout {
                        id: formCol

                        width: formFlick.width
                        spacing: Tokens.spacing.medium

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.large

                            StyledRect {
                                id: previewBox

                                implicitWidth: 72
                                implicitHeight: 72
                                radius: Tokens.rounding.large
                                color: Colours.palette.m3surfaceContainerHighest
                                clip: true

                                readonly property string preview: Icons.resolveThemeIcon(iconField.text || "", "application-x-executable")

                                IconImage {
                                    id: previewImage

                                    anchors.fill: parent
                                    anchors.margins: Tokens.padding.small
                                    asynchronous: true
                                    source: previewBox.preview
                                    visible: previewBox.preview.length > 0 && status === Image.Ready
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "apps"
                                    color: Colours.palette.m3onSurfaceVariant
                                    fontStyle: Tokens.font.icon.extraLarge
                                    visible: !previewImage.visible
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Tokens.spacing.medium

                                StyledTextField {
                                    id: nameField

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 52
                                    type: StyledTextField.Outlined
                                    placeholderText: Tr.tr("Application name")
                                    verticalPadding: Tokens.padding.medium
                                    horizontalPadding: Tokens.padding.medium
                                }

                                StyledTextField {
                                    id: commentField

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 52
                                    type: StyledTextField.Outlined
                                    placeholderText: Tr.tr("Description")
                                    verticalPadding: Tokens.padding.medium
                                    horizontalPadding: Tokens.padding.medium
                                }
                            }
                        }

                        StyledTextField {
                            id: genericField

                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            type: StyledTextField.Outlined
                            placeholderText: Tr.trCtx("Generic name", "desktop entry GenericName")
                            verticalPadding: Tokens.padding.medium
                            horizontalPadding: Tokens.padding.medium
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledTextField {
                                id: iconField

                                Layout.fillWidth: true
                                Layout.preferredHeight: 72
                                type: StyledTextField.Outlined
                                placeholderText: Tr.tr("Icon")
                                supportingText: Tr.tr("Theme name or file path")
                                verticalPadding: Tokens.padding.medium
                                horizontalPadding: Tokens.padding.medium
                            }

                            IconButton {
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: Tokens.padding.extraSmall
                                isRound: true
                                icon: "folder_open"
                                type: IconButton.Tonal
                                // Defer so this button isn't hidden before the click fully finishes
                                onClicked: Qt.callLater(() => root.startIconBrowse())
                            }
                        }

                        StyledTextField {
                            id: execField

                            Layout.fillWidth: true
                            Layout.preferredHeight: 72
                            type: StyledTextField.Outlined
                            placeholderText: Tr.tr("Command")
                            supportingText: Tr.tr("Exec line (%U, %f, … allowed)")
                            verticalPadding: Tokens.padding.medium
                            horizontalPadding: Tokens.padding.medium
                        }

                        StyledTextField {
                            id: pathField

                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            type: StyledTextField.Outlined
                            placeholderText: Tr.tr("Working directory")
                            verticalPadding: Tokens.padding.medium
                            horizontalPadding: Tokens.padding.medium
                        }

                        StyledTextField {
                            id: categoriesField

                            Layout.fillWidth: true
                            Layout.preferredHeight: 72
                            type: StyledTextField.Outlined
                            placeholderText: Tr.tr("Categories")
                            supportingText: Tr.tr("Separated by ; or ,")
                            verticalPadding: Tokens.padding.medium
                            horizontalPadding: Tokens.padding.medium
                        }

                        StyledTextField {
                            id: keywordsField

                            Layout.fillWidth: true
                            Layout.preferredHeight: 72
                            type: StyledTextField.Outlined
                            placeholderText: Tr.tr("Keywords")
                            supportingText: Tr.tr("Separated by ; or ,")
                            verticalPadding: Tokens.padding.medium
                            horizontalPadding: Tokens.padding.medium
                        }

                        StyledTextField {
                            id: startupField

                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            type: StyledTextField.Outlined
                            placeholderText: Tr.tr("Startup class")
                            verticalPadding: Tokens.padding.medium
                            horizontalPadding: Tokens.padding.medium
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            spacing: Tokens.spacing.medium

                            StyledText {
                                Layout.fillWidth: true
                                text: Tr.tr("Run in terminal")
                                font: Tokens.font.body.medium
                                color: Colours.palette.m3onSurface
                            }

                            StyledSwitch {
                                id: terminalSwitch
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.spacing.extraSmall
                    spacing: Tokens.spacing.small

                    Item {
                        Layout.fillWidth: true
                    }

                    IconTextButton {
                        text: Tr.tr("Cancel")
                        icon: "close"
                        type: IconButton.Text
                        onClicked: root.close()
                    }

                    IconTextButton {
                        text: Tr.tr("Save")
                        icon: "check"
                        type: IconButton.Tonal
                        inactiveColour: Colours.palette.m3primaryContainer
                        inactiveOnColour: Colours.palette.m3onPrimaryContainer
                        onClicked: root.save()
                    }
                }
            }

            Keys.onEscapePressed: root.close()
            Keys.onReturnPressed: root.save()
        }
    }

    // Seeker --pick (replaces the old in-tree folder browser)
    FileDialog {
        id: iconPicker

        title: Tr.tr("Choose icon")
        filterLabel: Tr.tr("Images")
        filters: Images.validImageExtensions
        onAccepted: path => {
            iconField.text = path.startsWith("file://") ? path.slice(7) : path;
        }
    }
}
