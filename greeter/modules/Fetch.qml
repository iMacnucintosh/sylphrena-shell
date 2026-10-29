pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

StyledRect {
    id: root

    required property real rootHeight
    readonly property int cBoxSize: Theme.font.bodyMedium * 2
    readonly property int logoCap: Theme.font.bodyMedium * 5

    implicitHeight: layout.implicitHeight + Theme.spacing.largeIncreased * 2
    radius: Theme.rounding.medium
    color: Theme.palette.m3surfaceContainer

    ColumnLayout {
        id: layout

        // Top/left/right only so implicitHeight stays content-driven.
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacing.largeIncreased
        spacing: Theme.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.medium

            StyledRect {
                implicitWidth: prompt.implicitWidth + Theme.spacing.medium * 2
                implicitHeight: prompt.implicitHeight + Theme.spacing.small * 2
                color: Theme.palette.m3primary
                radius: Theme.rounding.medium

                StyledText {
                    id: prompt

                    anchors.centerIn: parent
                    text: ">"
                    mono: true
                    color: Theme.palette.m3onPrimary
                    font.pixelSize: Theme.font.bodyMedium
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: "caelestiafetch.sh"
                mono: true
                elide: Text.ElideRight
                font.pixelSize: Theme.font.bodyMedium
            }

            Logo {
                Layout.preferredWidth: height
                Layout.preferredHeight: Theme.font.bodyMedium * 2
                visible: !iconLoader.active
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: bodyRow.implicitHeight

            RowLayout {
                id: bodyRow

                anchors.horizontalCenter: parent.horizontalCenter
                width: implicitWidth
                spacing: Theme.spacing.large

                Loader {
                    id: iconLoader

                    Layout.preferredHeight: root.logoCap
                    Layout.preferredWidth: root.logoCap
                    Layout.maximumHeight: root.logoCap
                    Layout.alignment: Qt.AlignVCenter
                    active: root.width > Theme.lock.largeLogoWidth
                    visible: active
                    sourceComponent: Logo {
                        width: height
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Theme.spacing.small

                    Repeater {
                        model: {
                            const items = [];
                            const rHeight = root.rootHeight;
                            if (rHeight > Theme.lock.fetch4LinesHeight)
                                items.push(`OS  : ${SysInfo.osPrettyName || SysInfo.osName}`);
                            if (rHeight > Theme.lock.fetch3LinesHeight)
                                items.push(`WM  : ${SysInfo.wm}`);
                            items.push(`USER: ${SysInfo.user}`);
                            items.push(`UP  : ${SysInfo.uptime}`);
                            return items;
                        }

                        StyledText {
                            required property string modelData

                            text: modelData
                            mono: true
                            elide: Text.ElideRight
                            font.pixelSize: root.width > Theme.lock.largeFontWidth ? Theme.font.bodyMedium : Theme.font.bodySmall
                        }
                    }
                }
            }
        }

        Loader {
            id: colourRowLoader

            Layout.topMargin: iconLoader.active ? Theme.spacing.extraSmall : 0
            Layout.alignment: Qt.AlignHCenter
            active: root.rootHeight > Theme.lock.showColourBoxRowHeight
            visible: active

            sourceComponent: RowLayout {
                id: coloursRow

                spacing: Theme.spacing.medium

                Repeater {
                    model: {
                        const slot = root.cBoxSize + coloursRow.spacing;
                        if (slot <= 0)
                            return 0;
                        return Math.max(0, Math.min(8, Math.floor((layout.width + coloursRow.spacing) / slot)));
                    }

                    StyledRect {
                        required property int index

                        implicitWidth: root.cBoxSize
                        implicitHeight: root.cBoxSize
                        color: Theme.term(index)
                        radius: Theme.rounding.medium
                    }
                }
            }
        }
    }
}
