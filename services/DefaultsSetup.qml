pragma Singleton

import Quickshell
import Quickshell.Io

// First run: a new install gets the recommended settings (assets/defaults/shell.json) and the wallpaper
// that ships with the shell. scripts/setup-defaults.py does it once and never touches an existing
// configuration; the config watcher applies the written file live, like ConfigMigration's rewrites.
Singleton {
    id: root

    Process {
        running: true
        command: ["python3", Quickshell.shellPath("scripts/setup-defaults.py")]
        stdinEnabled: false
    }
}
