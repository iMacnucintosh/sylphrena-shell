pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

RowLayout {
    id: root

    required property real screenHeight
    required property real screenWidth

    spacing: Theme.spacing.largeIncreased * 2

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.medium

        WeatherInfo {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignTop
            rootHeight: root.height
        }

        Fetch {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignTop
            rootHeight: root.height
        }

        PowerPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    Center {
        screenHeight: root.screenHeight
        screenWidth: root.screenWidth
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.medium

        ResourcePanel {
            Layout.fillWidth: true
        }

        CompanionPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
