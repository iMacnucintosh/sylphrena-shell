import "root:/services"
import "root:/config"
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight + BorderConfig.rounding * 2

    Content {
        id: content

        screen: root.screen
    }
}
