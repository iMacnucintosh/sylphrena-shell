pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Sylphrena
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Apps")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Default applications
        SectionHeader {
            first: true
            text: Tr.tr("Default applications")
        }

        DefaultRow {
            first: true
            icon: "terminal"
            label: Tr.trCtx("Terminal", "default app category")
            status: GlobalConfig.general.apps.terminal.join(" ")
            onSelected: app => GlobalConfig.general.apps.terminal = app.command
        }

        DefaultRow {
            icon: "volume_up"
            label: Tr.trCtx("Audio", "default app category")
            status: GlobalConfig.general.apps.audio.join(" ")
            onSelected: app => GlobalConfig.general.apps.audio = app.command
        }

        DefaultRow {
            icon: "play_circle"
            label: Tr.trCtx("Media playback", "default app category")
            status: GlobalConfig.general.apps.playback.join(" ")
            onSelected: app => GlobalConfig.general.apps.playback = app.command
        }

        DefaultRow {
            last: true
            icon: "folder"
            label: Tr.trCtx("File manager", "default app category")
            status: GlobalConfig.general.apps.explorer.join(" ")
            onSelected: app => GlobalConfig.general.apps.explorer = app.command
        }

        // Library
        SectionHeader {
            text: Tr.trCtx("Library", "app library")
        }

        NavRow {
            first: true
            last: true
            icon: "apps"
            text: Tr.tr("All apps")
            subtext: Tr.tr("Browse installed apps, set favourites and hidden")
            onClicked: root.nState.openSubPage(1)
        }
    }

    component DefaultRow: PopupRow {
        id: row

        property string searchQuery: ""

        // Same surface language as ConnectedRect / Nexus cards (not secondary accent).
        popupActiveColor: Colours.tPalette.m3surfaceContainer
        popupIdleColor: Colours.tPalette.m3surfaceContainer

        readonly property int popupHeight: root.flickable.height - y + root.flickable.contentY - Tokens.padding.large - Tokens.padding.extraExtraLarge

        signal selected(app: DesktopEntry)

        keepPopupAsChild: {
            if (root.nState.animatingContainer || root.opacity < 1)
                return true;

            let p = root.parent;
            while (p && p.objectName !== "PageContainer")
                p = p.parent;
            return p?.opacity < 1;
        }
        popup.topMovement: Math.max(Tokens.sizes.nexus.minPopupHeight - popupHeight, Tokens.padding.large)

        Loader {
            anchors.centerIn: parent
            active: row.popup.animDriver > 0
            onActiveChanged: {
                if (active)
                    row.searchQuery = "";
            }

            sourceComponent: Item {
                id: popupRoot

                // BlobPopup sizes from content.implicitWidth/Height — pin both so
                // SearchBar cannot collapse width and the list keeps a real viewport
                // (needed for VerticalFadeListView’s end mask, same as before SearchBar).
                readonly property int listHeight: Math.max(Tokens.sizes.nexus.minPopupHeight / 2, CUtils.clamp(row.popupHeight, Tokens.sizes.nexus.minPopupHeight, Tokens.sizes.nexus.maxPopupHeight) - search.implicitHeight - popupCol.spacing)

                implicitWidth: Tokens.sizes.nexus.popupWidth
                implicitHeight: search.implicitHeight + popupCol.spacing + listHeight
                width: implicitWidth
                height: implicitHeight

                ColumnLayout {
                    id: popupCol

                    anchors.fill: parent
                    spacing: Tokens.spacing.small

                    SearchBar {
                        id: search

                        Layout.fillWidth: true
                        placeholderText: Tr.tr("Search apps")
                        font: Tokens.font.body.medium
                        text: row.searchQuery
                        onTextChanged: row.searchQuery = text
                        // Inset field on the default surface (same idea as NavPane search).
                        bg.color: Colours.tPalette.m3surfaceContainerLowest

                        Component.onCompleted: forceActiveFocus()
                    }

                    StyledListView {
                        id: list

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        // Hard clip — no VerticalFade mask (keeps the blob edge crisp).

                        model: {
                            // Plain A–Z list — launcher favourites are irrelevant when
                            // picking a default Terminal / Audio / … app.
                            const q = (row.searchQuery || "").trim().toLowerCase();
                            const apps = [...DesktopEntries.applications.values];
                            const filtered = q ? apps.filter(a => {
                                const name = String(a.name || "").toLowerCase();
                                const comment = String(a.comment || "").toLowerCase();
                                const generic = String(a.genericName || "").toLowerCase();
                                const id = String(a.id || "").toLowerCase();
                                return name.includes(q) || comment.includes(q) || generic.includes(q) || id.includes(q);
                            }) : apps;
                            return filtered.sort((a, b) => a.name.localeCompare(b.name));
                        }

                        delegate: StateLayer {
                            id: appItem

                            required property DesktopEntry modelData
                            required property int index

                            anchors.fill: undefined
                            anchors.left: list.contentItem.left
                            anchors.right: list.contentItem.right
                            implicitHeight: itemLayout.implicitHeight + itemLayout.anchors.margins * 2
                            radius: Tokens.rounding.small

                            onClicked: {
                                row.popup.open = false;
                                row.selected(modelData);
                            }

                            RowLayout {
                                id: itemLayout

                                anchors.fill: parent
                                anchors.margins: Tokens.padding.medium
                                spacing: Tokens.spacing.medium

                                IconImage {
                                    asynchronous: true
                                    implicitSize: Math.round(Tokens.font.icon.large.pointSize * 1.8)
                                    source: Icons.resolveThemeIcon(appItem.modelData.icon || "")
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: appItem.modelData.name
                                        font: Tokens.font.body.small
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        visible: text
                                        text: (appItem.modelData.comment || appItem.modelData.genericName) ?? ""
                                        color: Colours.palette.m3outline
                                        font: Tokens.font.label.small
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
