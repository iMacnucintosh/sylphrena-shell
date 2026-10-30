pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import qs.services

// Thin wrapper over Quickshell's Greetd service: one password attempt at a
// time, greetd state machine hidden from the UI.
Singleton {
    id: root

    property string message
    property bool busy
    property bool success
    property string pending
    property bool recreateAfterCancel
    property bool launchRequested

    readonly property bool available: Greetd.available && !Theme.demo

    function submit(password: string): void {
        if (!password || root.busy || root.success)
            return;

        root.message = "";
        root.busy = true;
        root.pending = password;
        root.recreateAfterCancel = false;

        console.info(`greeter: auth submit user=${Theme.user} available=${root.available} state=${Greetd.state} len=${password.length}`);

        if (root.available) {
            if (Greetd.state === GreetdState.Inactive)
                Greetd.createSession(Theme.user);
            else {
                root.recreateAfterCancel = true;
                Greetd.cancelSession();
            }
        } else {
            demoAuth.restart();
        }
    }

    function fail(text: string): void {
        root.message = text;
        root.busy = false;
        root.success = false;
        root.pending = "";
        root.recreateAfterCancel = false;
        root.launchRequested = false;
        launchWatchdog.stop();
        if (root.available && Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();
    }

    function reset(): void {
        root.message = "";
        root.busy = false;
        root.success = false;
        root.pending = "";
        root.recreateAfterCancel = false;
        root.launchRequested = false;
        launchWatchdog.stop();
        demoAuth.stop();
        if (root.available && Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();
    }

    function launch(): void {
        if (root.launchRequested)
            return;

        const session = Sessions.current;
        if (!session) {
            root.fail("No se ha encontrado ninguna sesión.");
            return;
        }

        const desktop = session.desktop || "Hyprland";
        console.info(`greeter: launching ${session.name}: ${session.exec}`);

        if (Theme.demo) {
            Qt.quit();
            return;
        }

        root.launchRequested = true;
        root.busy = true;
        launchWatchdog.restart();

        // Desktop Exec → argv. Never `sh -c`: greetd tracks that process, and
        // a shell wrapper hid Plasma dying in <1s with no log.
        let argv = `${session.exec || ""}`.trim().split(/\s+/).filter(p => p.length);
        if (argv[0] === "Hyprland" || argv[0] === "/usr/bin/Hyprland")
            argv = ["/usr/bin/start-hyprland"];

        const launchCommand = [`${Theme.dir}/start-user-session.sh`, ...argv];

        // Quit explicitly on `launched`: this leaves a watchdog window to
        // recover the UI if greetd never acknowledges start_session.
        Greetd.launch(launchCommand, ["XDG_SESSION_TYPE=wayland", "XDG_SESSION_CLASS=user", `XDG_SESSION_DESKTOP=${desktop}`, `XDG_CURRENT_DESKTOP=${desktop}`], false);
    }

    Connections {
        function onAuthMessage(message: string, error: bool, responseRequired: bool, echoResponse: bool): void {
            console.info(`greeter: authMessage error=${error} needResponse=${responseRequired} echo=${echoResponse} msg=${JSON.stringify(message)}`);

            // Recoverable errors (fingerprint miss, etc.): show them, do NOT
            // cancel — Quickshell already ACKs non-response messages itself.
            if (error) {
                if (message)
                    root.message = message;
                return;
            }

            if (!responseRequired)
                return;

            if (!root.pending) {
                console.warn("greeter: auth prompt with empty pending password");
                Greetd.cancelSession();
                root.fail("Contraseña incorrecta. Inténtalo de nuevo.");
                return;
            }

            const password = root.pending;
            // Keep pending until success/failure in case greetd re-prompts.
            Greetd.respond(password);
        }

        function onAuthFailure(message: string): void {
            console.warn(`greeter: authFailure ${message}`);
            root.fail("Contraseña incorrecta. Inténtalo de nuevo.");
        }

        function onReadyToLaunch(): void {
            // Play the unlock fade first; GreeterSurface calls launch() when
            // the curtain is up so greetd never kills qs mid-animation (that
            // flash of letters/TTY is what the user was seeing).
            console.info("greeter: readyToLaunch — waiting for unlock fade");
            root.busy = false;
            root.pending = "";
            root.success = true;
        }

        function onLaunched(): void {
            console.info("greeter: session accepted — quitting under black curtain");
            launchWatchdog.stop();
            Qt.quit();
        }

        function onError(error: string): void {
            console.warn(`greeter: greetd error ${error}`);
            root.fail(`Error de autenticación: ${error}`);
        }

        function onStateChanged(): void {
            console.info(`greeter: greetd state=${Greetd.state}`);
            if (root.recreateAfterCancel && Greetd.state === GreetdState.Inactive) {
                root.recreateAfterCancel = false;
                Greetd.createSession(Theme.user);
            }
        }

        target: Greetd
    }

    // A failed greetd request must never strand the user behind the curtain.
    Timer {
        id: launchWatchdog

        interval: 4000
        onTriggered: root.fail("La sesión no ha respondido. Inténtalo de nuevo.")
    }

    // Demo mode (running inside a normal session): no greetd socket, so fake
    // the round-trip. Password "fail" exercises the error state.
    Timer {
        id: demoAuth

        interval: 700
        onTriggered: {
            if (root.pending === "fail")
                root.fail("Contraseña incorrecta. Inténtalo de nuevo.");
            else {
                root.pending = "";
                root.busy = false;
                root.success = true;
            }
        }
    }
}
