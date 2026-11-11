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

    // Installing one (scripts/install-companion.sh): which, what it is doing, how it ended
    property string installingId: ""
    // "download" | "deps" | "build" | "install" | "done" while it runs
    property string installStep: ""
    property string installError: ""
    // Last one that finished well, so a page can say "installed" without waiting for the re-check
    property string installedNow: ""

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

    // Download, build and install an app of the family. Needs the sudo password: it goes to the script
    // through stdin (kept in RAM only, see the script), never to a file, argv or the environment.
    function install(id: string, password: string): void {
        const c = root.find(id);
        if (!c || !password || installProc.running)
            return;
        root.installingId = id;
        root.installStep = "download";
        root.installError = "";
        root.installedNow = "";
        installProc._password = password;
        installProc.command = [Quickshell.shellPath("scripts/install-companion.sh"), c.repo];
        installProc.stdinEnabled = true;
        installTimeout.restart();
        installProc.running = true;
    }

    function cancelInstall(): void {
        if (installProc.running)
            installProc.running = false;
    }

    Process {
        id: installProc

        property string _password: ""

        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                if (!line.startsWith("==> "))
                    return;
                const l = line.slice(4);
                root.installStep = l.startsWith("Downloading") ? "download" : l.startsWith("Dependencies") ? "deps" : l.startsWith("Building") ? "build" : l.startsWith("Installing") ? "install" : l.startsWith("Done") ? "done" : root.installStep;
            }
        }
        stderr: StdioCollector {
            id: installErr
        }
        onStarted: {
            installProc.write(installProc._password + "\n");
            installProc._password = "";
            installProc.stdinEnabled = false;
        }
        onExited: code => {
            installTimeout.stop();
            const id = root.installingId;
            if (code === 0) {
                root.installedNow = id;
                root.installError = "";
            } else {
                // What sudo or the script said (never the password); a rejected password is told apart
                const said = `${installErr.text}`.split("\n").map(l => l.trim()).filter(l => l.length > 0 && !l.startsWith("==>"));
                const low = said.join(" ").toLowerCase();
                if (/incorrect password|try again|lo siento|contraseña incorrecta|no password was provided|intento/.test(low))
                    root.installError = Tr.tr("Incorrect password");
                else if (low.includes("locked") || low.includes("bloquead"))
                    root.installError = Tr.tr("Too many failed attempts. Wait a minute and try again.");
                else
                    root.installError = said.length > 0 ? said[said.length - 1] : Tr.tr("Failed (code %1)").arg(code);
                console.warn(`Companions: ${id}: install failed (${code}): ${said.join(" | ")}`);
            }
            root.installingId = "";
            root.installStep = "";
            root.check();
        }
    }

    Timer {
        id: installTimeout

        // Compiling can take a few minutes; a hung step must not keep the assistant busy forever
        interval: 20 * 60 * 1000
        onTriggered: root.cancelInstall()
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
