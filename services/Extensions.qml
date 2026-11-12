pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Sylphrena
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
    readonly property list<string> dirs: [Quickshell.shellPath("extensions"), root.userDir]
    // Where extensions installed by the user live (Things, or scripts/ext.py, put them here)
    readonly property string userDir: `${Paths.data}/extensions`

    readonly property var enabledIds: Array.from(GlobalConfig.extensions.enabled ?? [])

    // Every extension found, enabled or not: [{ dir, manifest }]
    property var discovered: []
    // Enabled extensions that are loaded: [{ id, dir, manifest, config, service, error }]
    property var loaded: []
    property bool ready: false

    // An extension that was asked to be enabled (IPC `enable`, right after Things or ext.py installed it)
    // before the shell had listed it or checked its system pieces: enabled as soon as it can be
    property string _enableId: ""

    // Enable a freshly installed extension once nothing is missing for it (system pieces installed)
    function _enableWhenReady(): void {
        const id = root._enableId;
        if (!id || !discovered.some(d => d.manifest.id === id) || !root.systemReady(id))
            return;
        root._enableId = "";
        if (!root.isEnabled(id))
            root.setEnabled(id, true);
    }

    // Look for extensions again (after installing or removing one)
    function rescan(): void {
        if (listProc.running)
            listProc.running = false;
        listProc.running = true;
    }

    // Delete the VPN connections of the provider type of an extension that is about to be removed (IPC
    // `prepareRemoval`, called by Things / ext.py before they delete its files): each one
    // is first handed to the extension (`forget(id, options)`: its files, its certificate copies), which
    // is loaded for a moment if it was disabled. Settings of the extension itself are kept.
    function _dropConnections(id: string): void {
        const typeId = `ext:${id}`;
        const list = GlobalConfig.utilities.vpn.provider;
        const mine = list.values.filter(p => p.type === typeId).map(p => ({
                    id: p.id,
                    options: JSON.parse(JSON.stringify(p.options ?? {}))
                }));
        if (mine.length === 0)
            return;
        let entry = loaded.find(e => e.id === id);
        let temporary = false;
        if (!entry?.service) {
            const d = discovered.find(x => x.manifest.id === id);
            entry = d ? root.create(d) : null;
            temporary = !!entry;
        }
        for (const c of mine)
            entry?.service?.forget?.(c.id, c.options);
        for (let i = list.values.length - 1; i >= 0; i--)
            if (list.values[i].type === typeId)
                list.remove(i);
        if (temporary)
            Qt.callLater(() => root.destroyEntry(entry));
    }

    // ── System pieces (manifest `system`: { install, uninstall, check }) ───────────────────────
    // Some extensions need something as root (a helper, a sudoers rule, a package). Installing and
    // removing them is Things' job (scripts/ext.py); the shell only checks, without root, whether they
    // are there: an extension with `system` can only be enabled once they are installed.
    // id -> "installed" | "outdated" | "missing" (only extensions that declare `system`)
    property var systemState: ({})

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

    // VPN provider types of the loaded extensions (manifest `vpnProviderType`): [{ id, name,
    // displayName, icon, editor, ext, service }]. The connections of a type are ordinary entries of the
    // VPN providers of the config with `type` = this id (`ext:<extension id>`) and their settings in
    // `options`; the extension's service connects them (see services/VPN.qml).
    readonly property var vpnProviderTypes: {
        const out = [];
        for (const e of loaded) {
            const t = e.manifest.contributes?.vpnProviderType;
            if (t && e.service)
                out.push({
                    id: `ext:${e.id}`,
                    name: t.name ?? e.manifest.name,
                    displayName: Tr.tr(t.name ?? e.manifest.name),
                    icon: t.icon ?? e.manifest.icon ?? "vpn_key",
                    editor: t.editor ?? "",
                    importer: t.importer ?? "",
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

    function hasSystem(manifest: var): bool {
        return !!manifest?.system?.install;
    }

    // True when the extension needs no system pieces or they are installed (current or not)
    function systemReady(id: string): bool {
        const d = discovered.find(x => x.manifest.id === id);
        return !root.hasSystem(d?.manifest) || ["installed", "outdated"].includes(systemState[id]);
    }

    function systemScript(d: var, key: string): string {
        const rel = d?.manifest.system?.[key] ?? "";
        // From a manifest: relative, no "..", only .sh
        if (!/^[A-Za-z0-9_\/.-]+\.sh$/.test(rel) || rel.includes("..") || rel.startsWith("/"))
            return "";
        return `${d.dir}/${rel}`;
    }

    // Re-run the `check` script of every extension that declares `system`
    function checkSystem(): void {
        const args = [];
        for (const d of discovered) {
            if (!root.hasSystem(d.manifest))
                continue;
            args.push(d.manifest.id, root.systemScript(d, "check"));
        }
        if (args.length === 0 || systemCheckProc.running)
            return;
        systemCheckProc.command = ["sh", "-c", 'while [ $# -gt 1 ]; do s=missing; if [ -n "$2" ]; then bash "$2" >/dev/null 2>&1; r=$?; [ $r -eq 0 ] && s=installed; [ $r -eq 3 ] && s=outdated; fi; echo "$1 $s"; shift 2; done', "sh", ...args];
        systemCheckProc.running = true;
    }

    function setEnabled(id: string, on: bool): void {
        // An extension with system pieces is enabled only once they are installed
        if (on && !root.systemReady(id))
            return;
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

    // The connection editor of a VPN provider type (`ext:<extension id>`), as an entry for ExtensionSlot (or null)
    function vpnEditorEntry(typeId: string): var {
        const t = vpnProviderTypes.find(x => x.id === typeId);
        const c = t?.editor ? root.component(t.ext, t.editor) : null;
        return c ? { id: `${t.ext.id}/vpnEditor`, ext: t.ext, component: c } : null;
    }

    // The import row (manifest `vpnProviderType.importer`) of a VPN provider type, shown first in the
    // Add provider page: fills connections from a file. As an entry for ExtensionSlot (or null)
    function vpnImporterEntry(typeId: string): var {
        const t = vpnProviderTypes.find(x => x.id === typeId);
        const c = t?.importer ? root.component(t.ext, t.importer) : null;
        return c ? { id: `${t.ext.id}/vpnImporter`, ext: t.ext, component: c } : null;
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

    // ── Compatibility (manifest `apiVersion`, `requires.sylphrena`) ─────────────────────────────
    // Version of the extension contract this shell implements, and of the shell itself (from the git
    // tag it was built from). An extension that needs more is listed but not loaded.
    readonly property int apiVersion: 1
    readonly property string shellVersion: CUtils.version

    // Numbers of "1", "1.2", "1.2.3" or "v1.2.3-dev" as [major, minor, patch]
    function _parts(v: string): var {
        const m = `${v}`.match(/^v?(\d+)(?:\.(\d+))?(?:\.(\d+))?/);
        return m ? [parseInt(m[1]), parseInt(m[2] ?? "0"), parseInt(m[3] ?? "0")] : null;
    }

    // -1, 0 or 1; null when one of them is not a version
    function compareVersions(a: string, b: string): var {
        const x = root._parts(a);
        const y = root._parts(b);
        if (!x || !y)
            return null;
        for (let i = 0; i < 3; i++)
            if (x[i] !== y[i])
                return x[i] < y[i] ? -1 : 1;
        return 0;
    }

    // Does `version` meet `spec`? Space separated comparators, all must hold: ">=0.3.0 <1.0.0", "=0.3.1".
    // An empty spec or an unknown shell version (a build without tags) always passes; a spec that does
    // not parse never does (a typo must not silently load an extension for the wrong version).
    function versionSatisfies(version: string, spec: string): bool {
        if (!spec || !version)
            return true;
        for (const part of `${spec}`.trim().split(/\s+/)) {
            const m = part.match(/^(>=|<=|>|<|=)?(\d+(?:\.\d+){0,2})$/);
            if (!m)
                return false;
            const c = root.compareVersions(version, m[2]);
            if (c === null)
                return false;
            const ok = { ">=": c >= 0, "<=": c <= 0, ">": c > 0, "<": c < 0, "=": c === 0 }[m[1] ?? "="];
            if (!ok)
                return false;
        }
        return true;
    }

    // "" when the extension can run here, else why not (shown as its error)
    function incompatibility(manifest: var): string {
        const api = manifest.apiVersion ?? 1;
        if (api > root.apiVersion)
            return Tr.tr("Needs a newer Sylphrena (extension API %1)").arg(api);
        const spec = manifest.requires?.sylphrena ?? "";
        if (!root.versionSatisfies(root.shellVersion, spec))
            return Tr.tr("Needs Sylphrena %1").arg(spec);
        return "";
    }

    function create(d: var): var {
        const e = { id: d.manifest.id, dir: d.dir, manifest: d.manifest, config: null, service: null, error: "" };
        e.config = configComp.createObject(root, { extId: e.id });
        e.error = root.incompatibility(d.manifest);
        if (e.error)
            return e;
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

    // Catalogs the extensions ship (i18n/<lang>.json), for Tr when the shell has no translation
    function updateCatalogs(): void {
        const cats = {};
        for (const d of discovered)
            if (d.i18n && Object.keys(d.i18n).length > 0)
                cats[d.manifest.id] = d.i18n;
        Tr.extraCatalogs = cats;
    }

    onDiscoveredChanged: {
        updateCatalogs();
        sync();
        checkSystem();
    }
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
        id: listProc

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
                root._enableWhenReady();
            }
        }
    }

    Process {
        id: systemCheckProc

        stdinEnabled: false
        stdout: StdioCollector {
            onStreamFinished: {
                const next = {};
                for (const line of text.split("\n")) {
                    const [id, state] = line.trim().split(" ");
                    if (id && state)
                        next[id] = state;
                }
                root.systemState = next;
                root._enableWhenReady();
            }
        }
    }

    IpcHandler {
        target: "extensions"

        // Look for extensions again (after installing or removing one by hand, or with Things)
        function rescan(): void {
            root.rescan();
        }

        // The folder with the shell's scripts (ext.py, install-extension.py): where Things finds the
        // tool that installs extensions, wherever the shell is installed
        function tools(): string {
            return Quickshell.shellPath("scripts");
        }

        // Every extension found: id, version, whether it is local (no hub receipt), enabled, error
        function list(): string {
            return JSON.stringify(root.discovered.map(d => ({
                        id: d.manifest.id,
                        name: d.manifest.name ?? d.manifest.id,
                        version: d.manifest.version ?? "",
                        kind: d.manifest.type ?? "",
                        dir: d.dir,
                        local: !d.source,
                        source: d.source ?? null,
                        enabled: root.isEnabled(d.manifest.id),
                        error: root.loaded.find(e => e.id === d.manifest.id)?.error || root.incompatibility(d.manifest)
                    })));
        }

        // → "ok" (enabled), "pending" (not listed yet, or its system pieces are still being checked: it
        // will be enabled as soon as it can) or "incompatible" (it will not be)
        function enable(id: string): string {
            const d = root.discovered.find(x => x.manifest.id === id);
            if (d && root.incompatibility(d.manifest))
                return "incompatible";
            if (d && root.systemReady(id)) {
                root.setEnabled(id, true);
                return "ok";
            }
            // Right after an install the listing / the check are still running: wait for them
            root._enableId = id;
            root.rescan();
            return "pending";
        }

        function disable(id: string): string {
            root.setEnabled(id, false);
            return "ok";
        }

        // The QML engine keeps the components it compiled: after the files of an extension that is
        // loaded changed (an update), reloading the shell is how the new code is used
        function reload(): void {
            Qt.callLater(() => Quickshell.reload(true));
        }

        // To call BEFORE deleting an extension's files (Things, `scripts/ext.py`): the extension forgets
        // its connections / data in the shell (files it keeps, VPN connections of its provider type)
        function prepareRemoval(id: string): string {
            root._dropConnections(id);
            return "ok";
        }

        function status(): string {
            return JSON.stringify({
                enabled: root.enabledIds,
                discovered: root.discovered.map(d => d.manifest.id),
                loaded: root.loaded.map(e => ({ id: e.id, error: e.error, hasService: !!e.service, widgets: (e.manifest.contributes?.widgets ?? []).length })),
                widgets: root.widgets.length,
                shellVersion: root.shellVersion,
                apiVersion: root.apiVersion,
                system: root.systemState
            });
        }
    }
}
