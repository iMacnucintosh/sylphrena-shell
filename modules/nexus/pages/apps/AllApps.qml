pragma ComponentBehavior: Bound

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

PageBase {
    id: root

    property string searchQuery: ""

    title: Tr.tr("All apps")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SearchBar {
            id: search

            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.medium
            placeholderText: Tr.tr("Search apps")
            font: Tokens.font.body.medium
            text: root.searchQuery
            onTextChanged: root.searchQuery = text
            bg.color: Colours.tPalette.m3surfaceContainerLowest

            Component.onCompleted: forceActiveFocus()
        }

        Repeater {
            id: list

            model: {
                const q = (root.searchQuery || "").trim().toLowerCase();
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

            ConnectedRect {
                id: appItem

                required property DesktopEntry modelData
                required property int index

                Layout.fillWidth: true
                first: index === 0
                last: index === list.count - 1
                implicitHeight: appRow.implicitHeight + appRow.anchors.margins * 2

                StateLayer {
                    onClicked: {
                        root.nState.selectedApp = appItem.modelData;
                        root.nState.openSubPage(2);
                    }
                }

                RowLayout {
                    id: appRow

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
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

                    MaterialIcon {
                        visible: Strings.testRegexList(GlobalConfig.launcher.favouriteApps, appItem.modelData.id)
                        text: "favorite"
                        fill: 1
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.small
                    }

                    MaterialIcon {
                        visible: Strings.testRegexList(GlobalConfig.launcher.hiddenApps, appItem.modelData.id)
                        text: "visibility_off"
                        fill: 0
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    MaterialIcon {
                        text: "chevron_right"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                    }
                }
            }
        }
    }
}
