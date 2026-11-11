pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Sylphrena.I18n
import qs.utils

// The apps that come with Sylphrena (Seeker, Things, and kitty, which it themes live): are they
// installed, open them. The welcome assistant presents them; the base package is what installs them.
Singleton {
    id: root

    // id, name, icon (Material Symbols), what it is, executable
    readonly property var all: [
        {
            id: "seeker",
            name: "Seeker",
            icon: "folder_open",
            description: Tr.tr("Material You file manager, in tune with the shell's theme"),
            bin: "seeker"
        },
        {
            id: "things",
            name: "Things",
            icon: "deployed_code",
            description: Tr.tr("Package manager: pacman, AUR and Flatpak in one list"),
            bin: "things"
        },
        {
            id: "kitty",
            name: "kitty",
            icon: "terminal",
            description: Tr.tr("Fast terminal: Sylphrena changes its colours live with your theme"),
            bin: "kitty"
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
