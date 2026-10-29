//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.modules
import qs.services

ShellRoot {
    id: root

    settings.watchFiles: false

    // Force singletons so the first frame already has palette/time/sessions.
    Component.onCompleted: {
        Theme;
        Time;
        Auth;
        Sessions;
        Weather;
        SysInfo;
        Resources;
        Shutdown;
        console.info(`greeter: demo=${Theme.demo} screens=${Quickshell.screens.length} user=${Theme.user} greetd=${Auth.available}`);
    }

    // Preview only — never instantiate FloatingWindow in the real greetd session
    // (xdg-shell on a bare greeter compositor has caused blank outputs).
    Loader {
        active: Theme.demo
        sourceComponent: FloatingWindow {
            id: demoWin

            title: "Caelestia greeter (demo)"
            color: "black"

            readonly property real previewH: Math.min(1008, (Quickshell.screens[0]?.height ?? 1440) * 0.7)
            readonly property real previewW: previewH * Theme.lock.ratio

            implicitWidth: previewW
            implicitHeight: previewH
            minimumSize.width: 640
            minimumSize.height: 400

            Item {
                id: demoStage

                anchors.centerIn: parent
                width: demoWin.previewW
                height: demoWin.previewH
                scale: Math.min(demoWin.width / width, demoWin.height / height)

                GreeterSurface {
                    anchors.fill: parent
                    screenHeight: demoWin.previewH / Theme.lock.heightMult
                    screenWidth: (Quickshell.screens[0]?.width ?? 2560) * (demoWin.previewH / ((Quickshell.screens[0]?.height ?? 1440) * Theme.lock.heightMult))
                }
            }

            Shortcut {
                sequences: ["Escape"]
                onActivated: Qt.quit()
            }

            onVisibleChanged: {
                if (!visible)
                    Qt.quit();
            }
        }
    }

    // Real greeter: fullscreen overlay per monitor.
    Variants {
        model: Theme.demo ? [] : Quickshell.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData

            screen: modelData
            // Opaque theme surface so a failed wallpaper/blur never yields a
            // featureless black compositor.
            color: Theme.palette.m3surface

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "caelestia-greeter"

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Component.onCompleted: console.info(`greeter: panel on ${modelData.name} ${modelData.width}x${modelData.height}`)

            GreeterSurface {
                anchors.fill: parent
                screenHeight: win.screen?.height ?? 1440
                screenWidth: win.screen?.width ?? 2560
            }
        }
    }
}
