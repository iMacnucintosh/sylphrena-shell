pragma Singleton

import QtQuick
import Quickshell

// Arms a fullscreen black curtain, then runs poweroff/reboot so the VT
// never flashes systemd lines or the Caelestia mark during teardown.
Singleton {
    id: root

    property bool armed
    property list<string> pending: []

    function arm(argv: list<string>): void {
        if (root.armed || !argv.length)
            return;
        root.pending = argv.slice();
        root.armed = true;
        // Let the curtain paint one frame before killing the machine.
        delay.restart();
    }

    Timer {
        id: delay

        interval: 150
        onTriggered: {
            if (!root.pending.length)
                return;
            Quickshell.execDetached(root.pending);
        }
    }
}
