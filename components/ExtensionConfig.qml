import QtQuick
import Quickshell.Io
import qs.utils

// Per-extension settings, stored in ~/.config/sylphrena/extensions/<id>.json (see
// services/Extensions.qml, which creates one per loaded extension and passes it as `ext.config`).
// Values are plain JSON. Use get(key, fallback) / set(key, value); `values` changes on every set
// so bindings that call get() update.
QtObject {
    id: root

    required property string extId

    property var values: ({})
    property bool loaded: false

    function get(key: string, fallback: var): var {
        return values.hasOwnProperty(key) ? values[key] : fallback;
    }

    function set(key: string, value: var): void {
        const next = Object.assign({}, values);
        next[key] = value;
        values = next;
        saveTimer.restart();
    }

    readonly property Timer saveTimer: Timer {
        interval: 300
        onTriggered: storage.setText(JSON.stringify(root.values, null, 2))
    }

    readonly property FileView storage: FileView {
        id: storage

        printErrors: false
        path: `${Paths.config}/extensions/${root.extId}.json`
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d && typeof d === "object" && !Array.isArray(d))
                    root.values = d;
            } catch (e) {
                console.warn(`ExtensionConfig(${root.extId}): bad JSON: ${e}`);
            }
            root.loaded = true;
        }
        onLoadFailed: err => {
            root.loaded = true;
            if (err !== FileViewError.FileNotFound)
                console.warn(`ExtensionConfig(${root.extId}): ${err}`);
        }
    }
}
