pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Extension loader, validated by the spike of 2026-11-10 (docs/PLAN-MODULAR.md §5.3): discovers
// extension folders, creates each one's service and exposes what they contribute.
// NOT wired in yet: nothing references this singleton, so it is never instantiated. Phase 3 of
// the plan wires it (shell.qml + the widget slot) and adds the enabled list and per-extension config.
Singleton {
    id: root

    // Shipped with the shell, then the user's own folder
    readonly property list<string> dirs: [Quickshell.shellPath("extensions"), `${Paths.data}/extensions`]

    // [{ id, dir, manifest, service, error }]
    property var loaded: []
    property bool ready: false

    // Flat list for the widget slot: [{ id, ext, component }]
    readonly property var widgets: {
        const out = [];
        for (const e of loaded)
            for (const w of (e.manifest.contributes?.widgets ?? [])) {
                const c = root.component(e, w.component);
                if (c)
                    out.push({ id: w.id, ext: e, component: c });
            }
        return out;
    }

    function service(id: string): var {
        return loaded.find(e => e.id === id)?.service ?? null;
    }

    // Compiled once per file
    property var _components: ({})

    function component(ext: var, file: string): var {
        if (!/^[A-Za-z0-9_\/-]+\.qml$/.test(file) || file.includes(".."))
            return null;
        const url = `file://${ext.dir}/${file}`;
        if (!_components[url]) {
            const c = Qt.createComponent(url);
            if (c.status !== Component.Ready) {
                console.warn(`Extensions: ${ext.id}/${file}: ${c.errorString()}`);
                return null;
            }
            _components[url] = c;
        }
        return _components[url];
    }

    function load(list: var): void {
        const out = [];
        for (const item of list) {
            const e = { id: item.manifest.id, dir: item.dir, manifest: item.manifest, service: null, error: "" };
            const file = item.manifest.contributes?.service;
            if (file) {
                const c = root.component(e, file);
                e.service = c ? c.createObject(root, { ext: e }) : null;
                if (!e.service)
                    e.error = "service failed";
            }
            out.push(e);
        }
        loaded = out;
        ready = true;
    }

    Process {
        running: true
        command: ["python3", Quickshell.shellPath("scripts/list-extensions.py"), ...root.dirs]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.load(JSON.parse(text));
                } catch (e) {
                    console.warn(`Extensions: bad listing: ${e}`);
                    root.ready = true;
                }
            }
        }
    }

    IpcHandler {
        target: "extensions"

        function status(): string {
            return JSON.stringify(root.loaded.map(e => ({ id: e.id, dir: e.dir, ticks: e.service?.ticks ?? null, probe: e.service?.probe ?? null, error: e.error })).concat([{ widgets: root.widgets.length }]));
        }
    }
}
