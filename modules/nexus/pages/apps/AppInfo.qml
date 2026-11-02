import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common
import qs.modules.launcher
import qs.modules.launcher.services

PageBase {
    id: root

    readonly property DesktopEntry app: nState.selectedApp
    readonly property bool favouriteByRegex: app && matchedByRegex(GlobalConfig.launcher.favouriteApps, app.id)
    readonly property bool hiddenByRegex: app && matchedByRegex(GlobalConfig.launcher.hiddenApps, app.id)
    readonly property string desktopPath: app ? Apps.resolveDesktopPath(app.id) : ""
    readonly property string categoriesText: app?.categories?.length ? [...app.categories].join(", ") : ""
    readonly property string keywordsText: app?.keywords?.length ? [...app.keywords].join(", ") : ""
    readonly property real detailLabelWidth: Math.max(
        appId.labelComp.implicitWidth,
        command.labelComp.implicitWidth,
        execRaw.labelComp.implicitWidth,
        workDir.labelComp.implicitWidth,
        startupClass.labelComp.implicitWidth,
        iconName.labelComp.implicitWidth,
        genericName.labelComp.implicitWidth,
        categories.labelComp.implicitWidth,
        keywords.labelComp.implicitWidth,
        terminal.labelComp.implicitWidth,
        desktopFile.labelComp.implicitWidth
    )

    function isRegexEntry(s: string): bool {
        return /^\^.*\$$/.test(s);
    }

    function matchedByRegex(filterList: list<string>, id: string): bool {
        return filterList.some(f => isRegexEntry(f) && new RegExp(f).test(id));
    }

    onAppChanged: {
        // Auto close when app lost
        if (!app)
            nState.closeSubPage();
    }

    title: Tr.tr("App info")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.large
            spacing: Tokens.spacing.large

            IconImage {
                asynchronous: true
                implicitSize: Math.round(Tokens.font.icon.large.pointSize * 3)
                source: Icons.resolveThemeIcon(root.app?.icon || "")
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Tokens.spacing.extraSmall / 2

                StyledText {
                    Layout.fillWidth: true
                    text: root.app?.name ?? ""
                    font: Tokens.font.title.medium
                    wrapMode: Text.WordWrap
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.app?.genericName ?? ""
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.app?.comment ?? ""
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                }
            }

            IconButton {
                // Match the full header row (icon + title + description).
                Layout.fillHeight: true
                Layout.preferredWidth: height
                Layout.minimumWidth: height
                Layout.maximumWidth: height
                icon: "open_in_new"
                type: IconButton.Tonal
                isRound: true
                font: Tokens.font.icon.medium
                inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                inactiveOnColour: Colours.palette.m3onSurfaceVariant
                enabled: !!root.app
                onClicked: Apps.launch(root.app)
            }
        }

        // Launcher
        SectionHeader {
            first: true
            text: Tr.tr("Launcher")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Favourite")
            subtext: root.favouriteByRegex ? Tr.tr("Matched by a regex in favouriteApps — edit the config file to change") : Tr.tr("Pin to the top of the launcher")
            enabled: !root.favouriteByRegex
            checked: root.app && Strings.testRegexList(GlobalConfig.launcher.favouriteApps, root.app.id)
            onToggled: {
                const apps = GlobalConfig.launcher.favouriteApps;
                GlobalConfig.launcher.favouriteApps = checked ? [...apps, root.app.id] : apps.filter(a => a !== root.app.id);
            }
        }

        ToggleRow {
            last: true
            text: Tr.tr("Hidden")
            subtext: root.hiddenByRegex ? Tr.tr("Matched by a regex in hiddenApps — edit the config file to change") : Tr.tr("Hide from the launcher")
            enabled: !root.hiddenByRegex
            checked: root.app && Strings.testRegexList(GlobalConfig.launcher.hiddenApps, root.app.id)
            onToggled: {
                const apps = GlobalConfig.launcher.hiddenApps;
                GlobalConfig.launcher.hiddenApps = checked ? [...apps, root.app.id] : apps.filter(a => a !== root.app.id);
            }
        }

        // Details (+ edit .desktop)
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.largeIncreased - parent.spacing
            Layout.bottomMargin: Tokens.spacing.extraSmall
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                text: Tr.tr("Details")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
                elide: Text.ElideRight
            }

            IconButton {
                icon: "edit"
                type: IconButton.Text
                font: Tokens.font.icon.small
                inactiveOnColour: Colours.palette.m3onSurfaceVariant
                enabled: !!root.app
                onClicked: editDialog.show(root.app)
            }
        }

        WrapInfoRow {
            id: appId

            first: true
            last: !command.visible && !execRaw.visible && !workDir.visible && !startupClass.visible
                  && !iconName.visible && !genericName.visible && !categories.visible
                  && !keywords.visible && !terminal.visible && !desktopFile.visible
            label: Tr.tr("App ID")
            value: root.app?.id ?? ""
            labelComp.Layout.preferredWidth: root.detailLabelWidth
        }

        WrapInfoRow {
            id: command

            visible: value.length > 0
            last: !execRaw.visible && !workDir.visible && !startupClass.visible
                  && !iconName.visible && !genericName.visible && !categories.visible
                  && !keywords.visible && !terminal.visible && !desktopFile.visible
            label: Tr.tr("Command")
            value: (root.app?.command ?? []).join(" ")
            labelComp.Layout.preferredWidth: root.detailLabelWidth
        }

        WrapInfoRow {
            id: execRaw

            visible: value.length > 0 && value !== command.value
            last: !workDir.visible && !startupClass.visible && !iconName.visible
                  && !genericName.visible && !categories.visible && !keywords.visible
                  && !terminal.visible && !desktopFile.visible
            label: Tr.tr("Exec")
            value: root.app?.execString ?? ""
            labelComp.Layout.preferredWidth: root.detailLabelWidth
        }

        WrapInfoRow {
            id: workDir

            visible: value.length > 0
            last: !startupClass.visible && !iconName.visible && !genericName.visible
                  && !categories.visible && !keywords.visible && !terminal.visible
                  && !desktopFile.visible
            label: Tr.tr("Working directory")
            value: root.app?.workingDirectory ?? ""
            labelComp.Layout.preferredWidth: root.detailLabelWidth
        }

        WrapInfoRow {
            id: startupClass

            visible: value.length > 0
            last: !iconName.visible && !genericName.visible && !categories.visible
                  && !keywords.visible && !terminal.visible && !desktopFile.visible
            label: Tr.tr("Startup class")
            value: root.app?.startupClass ?? ""
            labelComp.Layout.preferredWidth: root.detailLabelWidth
        }

        WrapInfoRow {
            id: iconName

            visible: value.length > 0
            last: !genericName.visible && !categories.visible && !keywords.visible
                  && !terminal.visible && !desktopFile.visible
            label: Tr.tr("Icon")
            value: root.app?.icon ?? ""
            labelComp.Layout.preferredWidth: root.detailLabelWidth
        }

        WrapInfoRow {
            id: genericName

            // Shown in header already; keep in details only when comment also exists
            // so both short + long descriptions stay visible there.
            visible: value.length > 0 && !!(root.app?.comment)
            last: !categories.visible && !keywords.visible && !terminal.visible && !desktopFile.visible
            label: Tr.trCtx("Generic name", "desktop entry GenericName")
            value: root.app?.genericName ?? ""
            labelComp.Layout.preferredWidth: root.detailLabelWidth
        }

        WrapInfoRow {
            id: categories

            visible: value.length > 0
            last: !keywords.visible && !terminal.visible && !desktopFile.visible
            label: Tr.tr("Categories")
            value: root.categoriesText
            labelComp.Layout.preferredWidth: root.detailLabelWidth
        }

        WrapInfoRow {
            id: keywords

            visible: value.length > 0
            last: !terminal.visible && !desktopFile.visible
            label: Tr.tr("Keywords")
            value: root.keywordsText
            labelComp.Layout.preferredWidth: root.detailLabelWidth
        }

        WrapInfoRow {
            id: terminal

            visible: !!(root.app?.runInTerminal)
            last: !desktopFile.visible
            label: Tr.tr("Terminal")
            value: Tr.tr("Runs in a terminal")
            labelComp.Layout.preferredWidth: root.detailLabelWidth
        }

        WrapInfoRow {
            id: desktopFile

            visible: value.length > 0
            last: true
            label: Tr.tr("Desktop file")
            value: root.desktopPath
            labelComp.Layout.preferredWidth: root.detailLabelWidth
        }

        // Reparents onto the window; same dialog as the launcher “Edit application…”
        DesktopEditDialog {
            id: editDialog
        }
    }

    component WrapInfoRow: ConnectedRect {
        id: row

        property alias label: label.text
        property alias value: value.text
        readonly property alias labelComp: label

        Layout.fillWidth: true
        implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2

        RowLayout {
            id: rowLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.medium

            StyledText {
                id: label

                Layout.alignment: Qt.AlignTop
                font: Tokens.font.body.small
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                id: value

                Layout.fillWidth: true
                Layout.maximumWidth: implicitWidth + 1 // Whyyyyyyyyy
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }
        }
    }
}
