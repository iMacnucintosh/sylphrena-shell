pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Sylphrena
import qs.utils
import qs.modules.welcome

// The welcome assistant: a window that introduces Sylphrena and offers its companion apps. It opens
// by itself the first time the shell runs (until it is finished or skipped) and can be opened again
// from Nexus → About, or with `qs -c sylphrena ipc call welcome open`.
Singleton {
    id: root

    readonly property string statePath: `${Paths.state}/welcome.json`

    // Loaded once from disk; null until then
    property var state: null
    readonly property bool open: window !== null
    property var window: null

    function show(): void {
        if (root.window)
            return;
        root.window = windowComp.createObject(root);
    }

    function close(): void {
        root.window?.dismiss();
    }

    // The assistant was finished or skipped: do not open it by itself again
    function markSeen(): void {
        stateFile.setText(JSON.stringify({ seen: true, version: CUtils.version }) + "\n");
        root.state = { seen: true };
    }

    Component {
        id: windowComp

        WelcomeWindow {
            onFinished: {
                root.markSeen();
                root.window = null;
            }
        }
    }

    FileView {
        id: stateFile

        path: root.statePath
        printErrors: false
        onLoaded: {
            try {
                root.state = JSON.parse(text());
            } catch (e) {
                root.state = {};
            }
        }
        onLoadFailed: root.state = {}
    }

    // First run: once the shell has been up for a moment (so it does not fight the startup)
    Timer {
        interval: 4000
        running: root.state !== null && !root.state.seen && !root.window
        onTriggered: root.show()
    }

    IpcHandler {
        target: "welcome"

        function open(): void {
            root.show();
        }

        function close(): void {
            root.close();
        }

        // Forget that it was seen (to test the first run)
        function reset(): void {
            stateFile.setText("{}\n");
            root.state = {};
        }
    }
}
