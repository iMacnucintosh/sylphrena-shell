import QtQuick
import Quickshell
import Sylphrena.Config
import qs.services
import qs.utils

// Spike: a per-extension service. Not a singleton: the base creates one instance and hands it to
// the extension's components.
Scope {
    id: root

    // Injected by the base
    required property var ext

    property int ticks: 0
    // Proves base singletons and the plugin are reachable from here
    readonly property string probe: `${Colours.palette.m3primary} state=${Paths.state.length > 0} cfg=${GlobalConfig.dashboard.enabled}`

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.ticks++
    }
}
