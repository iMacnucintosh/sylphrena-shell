pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.utils

// Extension loader (docs/PLAN-MODULAR.md §5). Finds the extension folders, knows which are enabled
// (config `extensions.enabled`; nothing by default) and, for each enabled one, creates its service
// and exposes what it contributes. The base never names an extension: it walks these lists.
Singleton {
    id: root

    // Shipped with the shell, then the user's own folder (the first folder that claims an id wins)
    readonly property list<string> dirs: [Quickshell.shellPath("extensions"), `${Paths.data}/extensions`]

    readonly property var enabledIds: Array.from(GlobalConfig.extensions.enabled ?? [])

    // Every extension found, enabled or not: [{ dir, manifest }]
    property var discovered: []
    // Enabled extensions that are loaded: [{ id, dir, manifest, config, service, error }]
    property var loaded: []
    property bool ready: false

    // Widgets declared by every discovered extension (for settings pages, even when disabled):
    // [{ id, extId, title, subtext, icon }]
    readonly property var widgetDecls: {
        const out = [];
        for (const d of discovered)
            for (const w of (d.manifest.contributes?.widgets ?? []))
                out.push({
                    id: w.id,
                    extId: d.manifest.id,
                    title: w.title ?? d.manifest.name ?? w.id,
                    subtext: w.subtext ?? d.manifest.description ?? "",
                    offNote: d.manifest.offNote ?? "",
                    hasSettings: !!d.manifest.contributes?.settings,
                    icon: w.icon ?? d.manifest.icon ?? "extension"
                });
        return out;
    }

    // Status icons declared by every discovered extension (labels for settings pages): [{ id, title }]
    readonly property var statusIconDecls: {
        const out = [];
        for (const d of discovered)
            for (const i of (d.manifest.contributes?.statusIcons ?? []))
                out.push({ id: i.id, title: i.title ?? d.manifest.name ?? i.id });
        return out;
    }

    // Bar status icons of the loaded extensions: [{ id, ext, component }]. The bar lists icons from
    // its own config (`bar.statusIcons`); an entry whose id is not a built-in one is drawn from here.
    readonly property var statusIcons: contributions("statusIcons")

    // Dashboard tabs of the loaded extensions: [{ id, text, icon, ext, component }]
    readonly property var dashboardTabs: contributions("dashboardTabs")

    // Bar popouts of the loaded extensions: [{ name, ext, component, dialog, parentIcon }].
    // A `dialog` popout takes the keyboard, and stays open while hovering its `parentIcon`.
    readonly property var popouts: contributions("popouts")

    // VPN providers of the loaded extensions (manifest `vpnProvider`), shaped like the entries of the
    // base VPN provider list so the selector can mix both: [{ id, name, displayName, icon, interface,
    // external, ext, service }]. Ids are namespaced (`ext:<extension id>`) so they never clash with
    // the ids of the providers in the config.
    readonly property var vpnProviders: {
        const out = [];
        for (const e of loaded) {
            const p = e.manifest.contributes?.vpnProvider;
            if (p && e.service)
                out.push({
                    id: `ext:${e.id}`,
                    name: p.name ?? e.manifest.name,
                    displayName: Tr.tr(p.name ?? e.manifest.name),
                    icon: p.icon ?? e.manifest.icon ?? "vpn_key",
                    interface: "",
                    external: true,
                    ext: e,
                    service: e.service
                });
        }
        return out;
    }

    // Widgets of the loaded extensions, ready to place: [{ id, ext, component }]
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

    // The first loaded extension that contributes a resource ring and has something to show:
    // { ext, ring } (the dashboard draws it in place of the storage ring), or null.
    readonly property var resourceRing: {
        for (const e of loaded)
            if (e.manifest.contributes?.resourceRing && e.service?.ring?.shown)
                return { ext: e, ring: e.service.ring };
        return null;
    }

    // Compiled components of one kind of contribution (`key` of manifest `contributes`): each item
    // `{ ..., component: "File.qml" }` becomes `{ ...item, ext, component: Component }`.
    function contributions(key: string): var {
        const out = [];
        for (const e of loaded)
            for (const item of (e.manifest.contributes?.[key] ?? [])) {
                const c = root.component(e, item.component);
                if (c)
                    out.push(Object.assign({}, item, { ext: e, component: c }));
            }
        return out;
    }

    function isEnabled(id: string): bool {
        return enabledIds.includes(id);
    }

    function setEnabled(id: string, on: bool): void {
        // Let the service clean up (stop a tunnel, …) before it is destroyed
        if (!on)
            loaded.find(e => e.id === id)?.service?.aboutToDisable?.();
        const ids = enabledIds.filter(i => i !== id);
        if (on)
            ids.push(id);
        GlobalConfig.extensions.enabled = ids;
    }

    // The settings component of an enabled extension, as an entry for ExtensionSlot (or null)
    function settingsEntry(extId: string): var {
        const e = loaded.find(x => x.id === extId);
        const file = e?.manifest.contributes?.settings;
        const c = file ? root.component(e, file) : null;
        return c ? { id: `${extId}/settings`, ext: e, component: c } : null;
    }

    function service(id: string): var {
        return loaded.find(e => e.id === id)?.service ?? null;
    }

    // id -> entry, for what is currently created
    property var _entries: ({})
    // url -> compiled Component
    property var _components: ({})

    function component(ext: var, file: string): var {
        // The file name comes from a manifest: no absolute paths, no "..", only .qml
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

    function create(d: var): var {
        const e = { id: d.manifest.id, dir: d.dir, manifest: d.manifest, config: null, service: null, error: "" };
        e.config = configComp.createObject(root, { extId: e.id });
        const file = d.manifest.contributes?.service;
        if (file) {
            const c = root.component(e, file);
            e.service = c ? c.createObject(root, { ext: e }) : null;
            if (!e.service)
                e.error = "service failed";
        }
        return e;
    }

    function destroyEntry(e: var): void {
        e.service?.destroy();
        e.config?.destroy();
    }

    // Create the services of newly enabled extensions, destroy those of disabled or vanished ones
    function sync(): void {
        const want = new Set(enabledIds);
        const found = new Set(discovered.map(d => d.manifest.id));
        const next = [];
        for (const d of discovered) {
            const id = d.manifest.id;
            let e = _entries[id];
            if (want.has(id)) {
                if (!e) {
                    e = create(d);
                    _entries[id] = e;
                }
                next.push(e);
            } else if (e) {
                destroyEntry(e);
                delete _entries[id];
            }
        }
        for (const id of Object.keys(_entries))
            if (!found.has(id)) {
                destroyEntry(_entries[id]);
                delete _entries[id];
            }
        loaded = next;
    }

    onDiscoveredChanged: sync()
    onEnabledIdsChanged: sync()

    Component {
        id: configComp

        ExtensionConfig {}
    }

    // The user's folders must exist so that extensions can be dropped in / write their config
    Process {
        running: true
        command: ["mkdir", "-p", `${Paths.data}/extensions`, `${Paths.config}/extensions`]
        stdinEnabled: false
    }

    Process {
        running: true
        command: ["python3", Quickshell.shellPath("scripts/list-extensions.py"), ...root.dirs]
        stdinEnabled: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.discovered = JSON.parse(text);
                } catch (e) {
                    console.warn(`Extensions: bad listing: ${e}`);
                }
                root.ready = true;
            }
        }
    }

    IpcHandler {
        target: "extensions"

        function status(): string {
            return JSON.stringify({
                enabled: root.enabledIds,
                discovered: root.discovered.map(d => d.manifest.id),
                loaded: root.loaded.map(e => ({ id: e.id, error: e.error, hasService: !!e.service, widgets: (e.manifest.contributes?.widgets ?? []).length })),
                widgets: root.widgets.length
            });
        }
    }
}
