pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Sylphrena
import Sylphrena.Config
import Sylphrena.Models
import qs.utils

Searcher {
    id: root

    signal editRequested(entry: DesktopEntry)

    property bool editingDesktop: false

    readonly property string applicationsHome: `${Quickshell.env("XDG_DATA_HOME") || `${Quickshell.env("HOME")}/.local/share`}/applications`

    function requestEdit(entry: DesktopEntry): void {
        root.editRequested(entry);
    }

    function desktopSearchDirs(): var {
        const home = Quickshell.env("HOME");
        const dataHome = Quickshell.env("XDG_DATA_HOME") || `${home}/.local/share`;
        return [
            `${dataHome}/applications`,
            `${dataHome}/flatpak/exports/share/applications`,
            `/var/lib/flatpak/exports/share/applications`,
            `/usr/local/share/applications`,
            `/usr/share/applications`
        ];
    }

    function desktopFileName(id: string): string {
        return id.endsWith(".desktop") ? id : `${id}.desktop`;
    }

    function localOverridePath(id: string): string {
        return `${root.applicationsHome}/${root.desktopFileName(id)}`;
    }

    function readDesktopFile(path: string): string {
        if (!path)
            return "";
        io.path = path;
        // text() respects blockAllReads — do not trust io.loaded after path churn
        try {
            return io.text() || "";
        } catch (e) {
            return "";
        }
    }

    function hasLocalOverride(id: string): bool {
        return root.readDesktopFile(root.localOverridePath(id)).length > 0;
    }

    function resolveDesktopPath(id: string): string {
        const name = root.desktopFileName(id);
        for (const dir of root.desktopSearchDirs()) {
            const path = `${dir}/${name}`;
            if (root.readDesktopFile(path).length > 0)
                return path;
        }
        return "";
    }

    function setDesktopKey(text: string, key: string, value: string): string {
        const line = `${key}=${value}`;
        const pat = new RegExp(`^${key.replace(/[[\]]/g, "\\$&")}=.*$`, "m");
        if (pat.test(text))
            return text.replace(pat, line);
        if (value === "")
            return text;
        // Match [Desktop Entry] with optional \r
        if (/\[Desktop Entry\]\r?\n/.test(text))
            return text.replace(/\[Desktop Entry\]\r?\n/, m => `${m}${line}\n`);
        return `[Desktop Entry]\n${line}\n${text}`;
    }

    /// Categories/Keywords: accept `,` or `;`, emit `A;B;` (desktop-entry form).
    function normalizeDesktopList(value: string): string {
        const parts = String(value || "").split(/[;,]/).map(p => p.trim()).filter(p => p.length > 0);
        return parts.length ? `${parts.join(";")};` : "";
    }

    function formatDesktopList(values: var): string {
        if (!values || !values.length)
            return "";
        return [...values].join("; ");
    }

    /// meta: name, comment, icon, genericName, exec, categories, keywords,
    ///       startupClass, workingDirectory, terminal (bool)
    function saveDesktopMetadata(id: string, meta: var): bool {
        const dest = root.localOverridePath(id);
        const src = root.resolveDesktopPath(id);
        if (!src) {
            console.warn(`Apps: no .desktop found for ${id}`);
            return false;
        }

        // Ensure a writable override under ~/.local/share/applications
        if (src !== dest) {
            if (!CUtils.copyFile(Qt.resolvedUrl(src), Qt.resolvedUrl(dest), true)) {
                console.warn(`Apps: failed to copy ${src} -> ${dest}`);
                return false;
            }
        }

        let text = root.readDesktopFile(dest);
        if (!text.length) {
            console.warn(`Apps: cannot read override ${dest}`);
            return false;
        }

        const m = meta || {};
        if (m.name !== undefined && m.name !== null)
            text = root.setDesktopKey(root.setDesktopKey(root.setDesktopKey(text, "Name", m.name), "Name[es]", m.name), "Name[es_ES]", m.name);
        if (m.comment !== undefined && m.comment !== null)
            text = root.setDesktopKey(root.setDesktopKey(root.setDesktopKey(text, "Comment", m.comment), "Comment[es]", m.comment), "Comment[es_ES]", m.comment);
        if (m.genericName !== undefined && m.genericName !== null)
            text = root.setDesktopKey(root.setDesktopKey(root.setDesktopKey(text, "GenericName", m.genericName), "GenericName[es]", m.genericName), "GenericName[es_ES]", m.genericName);
        if (m.icon !== undefined && m.icon !== null)
            text = root.setDesktopKey(text, "Icon", m.icon);
        if (m.exec !== undefined && m.exec !== null)
            text = root.setDesktopKey(text, "Exec", m.exec);
        if (m.categories !== undefined && m.categories !== null)
            text = root.setDesktopKey(text, "Categories", root.normalizeDesktopList(m.categories));
        if (m.keywords !== undefined && m.keywords !== null)
            text = root.setDesktopKey(text, "Keywords", root.normalizeDesktopList(m.keywords));
        if (m.startupClass !== undefined && m.startupClass !== null)
            text = root.setDesktopKey(text, "StartupWMClass", m.startupClass);
        if (m.workingDirectory !== undefined && m.workingDirectory !== null)
            text = root.setDesktopKey(text, "Path", m.workingDirectory);
        if (m.terminal !== undefined && m.terminal !== null)
            text = root.setDesktopKey(text, "Terminal", m.terminal ? "true" : "false");

        io.path = dest;
        io.setText(text);
        Quickshell.execDetached(["update-desktop-database", root.applicationsHome]);
        return true;
    }

    function resetDesktopOverride(id: string): bool {
        const path = root.localOverridePath(id);
        if (!root.hasLocalOverride(id))
            return false;
        const ok = CUtils.deleteFile(Qt.resolvedUrl(path));
        if (ok)
            Quickshell.execDetached(["update-desktop-database", root.applicationsHome]);
        return ok;
    }

    function toggleFavourite(id: string): void {
        const apps = GlobalConfig.launcher.favouriteApps;
        if (Strings.testRegexList(apps, id)) {
            // Drop exact id and any ^...$ regex entry that matches this app
            GlobalConfig.launcher.favouriteApps = apps.filter(a => {
                if (a === id)
                    return false;
                if (/^\^.*\$$/.test(a)) {
                    try {
                        return !(new RegExp(a).test(id));
                    } catch (e) {
                        return true;
                    }
                }
                return true;
            });
        } else {
            GlobalConfig.launcher.favouriteApps = [...apps, id];
        }
    }

    function isFavourite(id: string): bool {
        return Strings.testRegexList(GlobalConfig.launcher.favouriteApps, id);
    }

    function hideFromLauncher(id: string): void {
        const apps = GlobalConfig.launcher.hiddenApps;
        if (!Strings.testRegexList(apps, id))
            GlobalConfig.launcher.hiddenApps = [...apps, id];
    }

    function launch(entry: DesktopEntry): void {
        appDb.incrementFrequency(entry.id);

        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: [...GlobalConfig.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        else
            entry.execute();
    }

    function search(search: string): var {
        const prefix = GlobalConfig.launcher.specialPrefix;

        if (search.startsWith(`${prefix}i `)) {
            keys = ["id", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}c `)) {
            keys = ["categories", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}d `)) {
            keys = ["comment", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}e `)) {
            keys = ["execString", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}w `)) {
            keys = ["startupClass", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}g `)) {
            keys = ["genericName", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}k `)) {
            keys = ["keywords", "name"];
            weights = [0.9, 0.1];
        } else {
            keys = ["name"];
            weights = [1];

            if (!search.startsWith(`${prefix}t `))
                return query(search).map(e => e.entry);
        }

        const results = query(search.slice(prefix.length + 2)).map(e => e.entry);
        if (search.startsWith(`${prefix}t `))
            return results.filter(a => a.runInTerminal);
        return results;
    }

    function selector(item: var): string {
        return keys.map(k => item[k]).join(" ");
    }

    list: appDb.apps
    useFuzzy: GlobalConfig.launcher.useFuzzy.apps

    FileView {
        id: io

        printErrors: false
        preload: false
        blockAllReads: true
        blockWrites: true // sync write so path isn't reused before flush
    }

    AppDb {
        id: appDb

        path: `${Paths.state}/apps.sqlite`
        favouriteApps: GlobalConfig.launcher.favouriteApps
        entries: DesktopEntries.applications.values.filter(a => !Strings.testRegexList(GlobalConfig.launcher.hiddenApps, a.id))
    }
}
