pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Sylphrena.Config
import qs.components
import qs.services

Column {
    id: root

    required property ShellScreen screen
    required property bool fullscreen
    required property var popouts
    required property Item barItem

    spacing: Tokens.spacing.small

    Repeater {
        model: Activities.mappedActivities

        ActivityPill {
            required property var modelData

            screen: root.screen
            fullscreen: root.fullscreen
            activity: modelData
            popouts: root.popouts
            barItem: root.barItem
        }
    }
}
