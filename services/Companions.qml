pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Sylphrena.I18n
import qs.utils

// The apps of the Sylphrena family that go well with the shell (Seeker, Things): are they installed,
// open them. The welcome assistant offers to install them (see scripts/install-companion.sh).
Singleton {
    id: root

    // id, name, icon (Material Symbols), what it is, GitHub repo, executable
    readonly property var all: [
        {
            id: "seeker",
            name: "Seeker",
            icon: "folder_open",
            description: Tr.tr("Material You file manager, in tune with the shell's theme"),
            repo: "iMacnucintosh/seeker",
            bin: "seeker"
        },
        {
            id: "things",
            name: "Things",
            icon: "deployed_code",
            description: Tr.tr("Package manager: pacman, AUR and Flatpak in one list"),
            repo: "iMacnucintosh/things",
            bin: "things"
        }
    ]

    // id -> true / false once checked
    property var installed: ({})
    property bool checked: false

    function find(id: string): var {
        return root.all.find(c => c.id === id) ?? null;
    }

    function isInstalled(id: string): bool {
        return root.installed[id] === true;
    }

    // Look again (after an install, or when the user comes back to a page that shows them)
    function check(): void {
        if (!checkProc.running)
            checkProc.running = true;
    }

    // Open an app of the family. The shell's PATH does not include ~/.local/bin, where a build from
    // source installs, so that one is tried first.
    function launch(id: string): void {
        const c = root.find(id);
        if (!c)
            return;
        Quickshell.execDetached(["sh", "-c", 'if [ -x "$HOME/.local/bin/$1" ]; then exec "$HOME/.local/bin/$1"; else exec "$1"; fi', "sh", c.bin]);
    }

    Process {
        id: checkProc

        command: ["sh", "-c", 'for b in "$@"; do if command -v "$b" >/dev/null 2>&1 || [ -x "$HOME/.local/bin/$b" ]; then echo "$b 1"; else echo "$b 0"; fi; done', "sh", ...root.all.map(c => c.bin)]
        stdinEnabled: false
        stdout: StdioCollector {
            onStreamFinished: {
                const next = {};
                for (const line of text.split("\n")) {
                    const [bin, ok] = line.trim().split(" ");
                    const c = root.all.find(x => x.bin === bin);
                    if (c)
                        next[c.id] = ok === "1";
                }
                root.installed = next;
                root.checked = true;
            }
        }
    }

    Component.onCompleted: root.check()
}
