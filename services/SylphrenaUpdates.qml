pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Sylphrena
import Sylphrena.I18n

// New releases of Sylphrena (the shell, the CLI, Seeker, Things) for a machine that installed it with its packages:
// scripts/check-sylphrena-releases.py compares the installed versions with the latest release of each repository.
// The bar's updates icon and Nexus → Updates show them; "Update" runs the installer in --update mode in a terminal.
Singleton {
    id: root

    // TODO: every minute while it is being tested in the VM; then every few hours
    readonly property int checkMinutes: 1

    // [{ pkg, name, repo, installed, latest, notes, url }]
    property var updates: []
    readonly property bool hasUpdate: updates.length > 0
    // The release of the shell itself, if it is one of them (its notes are the ones shown)
    readonly property var shell: updates.find(u => u.pkg === "sylphrena-shell-git") ?? null
    readonly property string version: shell ? shell.latest : (updates[0]?.latest ?? "")
    property bool updating: false

    property var _announced: []

    function check(): void {
        if (!proc.running)
            proc.running = true;
    }

    function update(): void {
        root.updating = true;
        Updates.runInTerminal(`python3 ${JSON.stringify(Quickshell.shellPath("scripts/installer.py"))} --update`, Tr.tr("Updating Sylphrena"));
        // The terminal stays open until it is closed; check again after a while
        afterUpdate.restart();
    }

    function announce(): void {
        const fresh = root.updates.filter(u => !root._announced.includes(`${u.pkg}@${u.latest}`));
        if (!fresh.length)
            return;
        root._announced = [...root._announced, ...fresh.map(u => `${u.pkg}@${u.latest}`)];
        const names = fresh.map(u => `${u.name} ${u.latest}`).join(", ");
        Toaster.toast(Tr.tr("New version of Sylphrena"), Tr.tr("%1 · update it from Nexus → Updates").arg(names), "sylphrena");
    }

    Timer {
        interval: root.checkMinutes * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.check()
    }

    Timer {
        id: afterUpdate

        interval: 60 * 1000
        onTriggered: {
            root.updating = false;
            root.check();
        }
    }

    Process {
        id: proc

        command: ["python3", Quickshell.shellPath("scripts/check-sylphrena-releases.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.updates = JSON.parse(text).updates ?? [];
                } catch (e) {
                    return;
                }
                root.announce();
            }
        }
    }
}
