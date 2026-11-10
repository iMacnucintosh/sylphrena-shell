pragma Singleton

import Quickshell
import Quickshell.Io

// Renames config keys that changed between versions (scripts/migrate-config.py, idempotent). The
// config watcher reloads shell.json when the script rewrites it, so migrated values apply live.
Singleton {
    Process {
        running: true
        command: ["python3", Quickshell.shellPath("scripts/migrate-config.py")]
        stdinEnabled: false
    }
}
