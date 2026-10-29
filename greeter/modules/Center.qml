pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property real screenHeight
    required property real screenWidth

    readonly property real centerScale: Math.min(1, root.screenHeight / 1440)
    readonly property int centerWidth: Math.round(Theme.lock.centerWidth * root.centerScale)

    Layout.preferredWidth: centerWidth
    Layout.fillWidth: false
    Layout.fillHeight: true

    spacing: Theme.spacing.largeIncreased

    Clock {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.spacing.large
        centerScale: root.centerScale
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter

        text: Time.dateStr
        color: Theme.palette.m3onSurface
        font.pixelSize: Math.round(Theme.font.titleMedium * root.centerScale)
        font.weight: Font.DemiBold
    }

    ProfilePic {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.spacing.extraLarge * root.centerScale
        Layout.bottomMargin: Theme.spacing.large * root.centerScale
        centerWidth: root.centerWidth
    }

    PasswordInput {
        id: passwordInput

        Layout.alignment: Qt.AlignHCenter
        centerScale: Math.max(0.8, root.centerScale)
        centerWidth: root.centerWidth
    }

    StateMessage {
        Layout.fillWidth: true
    }

    SessionSelector {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.spacing.small
    }
}
