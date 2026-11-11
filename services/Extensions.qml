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

    // ── System pieces (manifest `system`: { install, uninstall, check, description }) ──────────
    // Some extensions need something as root (a helper, a sudoers rule, a package). They declare
    // shell scripts for it; installing asks for the password once, in Nexus → Complements, and is
    // separate from enabling: an extension with `system` can only be enabled once installed.
    // id -> "installed" | "outdated" | "missing" (only extensions that declare `system`)
    property var systemState: ({})
    // The extension whose system pieces are being installed / removed, and which of the two
    property string systemBusyId: ""
    property string systemAction: ""
    // Last failure, for the extension in systemErrorId
    property string systemErrorId: ""
    property string systemError: ""

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

    // Install (action "install") or remove ("uninstall") the system pieces of an extension, as root.
    // The password goes to sudo through stdin and is dropped right after; never to a file or argv.
    // Removing disables the extension first (its service stops what it runs).
    function runSystem(id: string, action: string, password: string): void {
        const d = discovered.find(x => x.manifest.id === id);
        const script = root.systemScript(d, action);
        if (!script || systemProc.running)
            return;
        if (action === "uninstall" && root.isEnabled(id))
            root.setEnabled(id, false);
        root.systemBusyId = id;
        root.systemAction = action;
        root.systemErrorId = "";
        root.systemError = "";
        systemProc._password = password;
        systemProc.command = ["sudo", "-S", "-k", "-p", "", "--", "bash", script];
        systemProc.stdinEnabled = true;
        systemTimeout.restart();
        systemProc.running = true;
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

    onDiscoveredChanged: {
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
            }
        }
    }

    Process {
        id: systemProc

        property string _password: ""

        stdinEnabled: true
        stdout: StdioCollector {}
        stderr: StdioCollector {
            id: systemErr
        }
        onStarted: {
            systemProc.write(systemProc._password + "\n");
            systemProc._password = "";
            systemProc.stdinEnabled = false;
        }
        onExited: code => {
            systemTimeout.stop();
            const id = root.systemBusyId;
            root.systemBusyId = "";
            if (code !== 0) {
                // What sudo or the script said (never the password); a rejected password is told apart
                const said = `${systemErr.text}`.split("\n").map(l => l.trim()).filter(l => l.length > 0);
                const low = said.join(" ").toLowerCase();
                root.systemErrorId = id;
                if (/incorrect password|try again|lo siento|contraseña incorrecta|no password was provided|intento/.test(low))
                    root.systemError = Tr.tr("Incorrect password");
                else if (low.includes("locked") || low.includes("bloquead"))
                    root.systemError = Tr.tr("Too many failed attempts. Wait a minute and try again.");
                else
                    root.systemError = said.length > 0 ? said[said.length - 1] : Tr.tr("Failed (code %1)").arg(code);
                console.warn(`Extensions: ${id}: system ${root.systemAction} failed (${code}): ${said.join(" | ")}`);
            }
            root.systemAction = "";
            root.checkSystem();
        }
    }

    Timer {
        id: systemTimeout

        // A package download can take a while; a hung sudo must not keep the card busy forever
        interval: 5 * 60 * 1000
        onTriggered: {
            if (systemProc.running)
                systemProc.running = false;
        }
    }

    IpcHandler {
        target: "extensions"

        function status(): string {
            return JSON.stringify({
                enabled: root.enabledIds,
                discovered: root.discovered.map(d => d.manifest.id),
                loaded: root.loaded.map(e => ({ id: e.id, error: e.error, hasService: !!e.service, widgets: (e.manifest.contributes?.widgets ?? []).length })),
                widgets: root.widgets.length,
                system: root.systemState
            });
        }
    }
}
