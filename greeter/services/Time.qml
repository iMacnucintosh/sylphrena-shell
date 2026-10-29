pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property date now: new Date()

    readonly property var locale: Qt.locale("es_ES")
    readonly property string hourStr: Qt.formatTime(root.now, "HH")
    readonly property string minuteStr: Qt.formatTime(root.now, "mm")
    readonly property string dateStr: root.locale.toString(root.now, "dddd • d MMM").toUpperCase()

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }
}
