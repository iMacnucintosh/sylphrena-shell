pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Sylphrena
import Sylphrena.I18n
import qs.utils

// What Sylphrena itself can update, as two more sources of the updates list (next to pacman, the AUR and Flatpak):
//  · SYLPHRENA: its packages (the shell, the CLI, Seeker, Things) behind their latest release, on a machine that
//    installed them; updated by the installer in --update mode.
//  · EXTENSION: the extensions installed from the hub whose catalog has a newer version; updated with
//    `ext.py update-hub` (what Things does too).
// scripts/check-sylphrena-releases.py finds them; Updates merges `entries` into its list and its "Update" runs them
// after the system packages, with the same password (scripts/run-system-update.sh --sylphrena --extension <id>).
Singleton {
    id: root

    // TODO: every minute while it is being tested in the VM; then every few hours
    readonly property int checkMinutes: 1

    // [{ pkg, name, repo, installed, latest, notes, url }]
    property var updates: []
    // [{ id, name, installed, latest }]
    property var extensions: []

    // The release of the shell itself, if it is one of them (its notes are the ones shown in Nexus)
    readonly property var shell: updates.find(u => u.pkg === "sylphrena-shell-git") ?? null
    readonly property string version: shell ? shell.latest : (updates[0]?.latest ?? "")
    readonly property bool hasUpdate: updates.length > 0

    // In the shape of Updates.packages: { name, from, to, source, … }
    readonly property var entries: [...updates.map(u => ({
                name: u.name,
                from: u.installed,
                to: u.latest,
                source: "SYLPHRENA",
                pkg: u.pkg,
                url: u.url,
                desc: ""
            })), ...extensions.map(e => ({
                name: Tr.tr(e.name),
                from: e.installed,
                to: e.latest,
                source: "EXTENSION",
                id: e.id,
                desc: ""
            }))]

    // What has been announced already (per version), kept across restarts: each new version is announced once
    readonly property var _announced: {
        try {
            return JSON.parse(announcedFile.text()).announced ?? [];
        } catch (e) {
            return [];
        }
    }

    function check(): void {
        if (!proc.running)
            proc.running = true;
    }

    function announce(): void {
        const keys = [...root.updates.map(u => `${u.pkg}@${u.latest}`), ...root.extensions.map(e => `ext:${e.id}@${e.latest}`)];
        const fresh = root.entries.filter((_, i) => !root._announced.includes(keys[i]));
        if (!fresh.length)
            return;
        announcedFile.setText(JSON.stringify({ announced: [...new Set([...root._announced, ...keys])] }));
        const own = fresh.some(e => e.source === "SYLPHRENA");
        const exts = fresh.some(e => e.source === "EXTENSION");
        const title = own && exts ? Tr.tr("Updates available") : own ? Tr.tr("New version of Sylphrena") : Tr.tr("New extension updates");
        Toaster.toast(title, fresh.map(e => e.name).join("  ·  "), "sylphrena");
    }

    FileView {
        id: announcedFile

        path: `${Paths.state}/updates-announced.json`
        printErrors: false
        blockLoading: true
    }

    Timer {
        interval: root.checkMinutes * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.check()
    }

    Process {
        id: proc

        command: ["python3", Quickshell.shellPath("scripts/check-sylphrena-releases.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                let data;
                try {
                    data = JSON.parse(text);
                } catch (e) {
                    return;
                }
                root.updates = data.updates ?? [];
                root.extensions = data.extensions ?? [];
                root.announce();
            }
        }
    }
}
