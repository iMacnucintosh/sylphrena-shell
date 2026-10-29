pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Self-contained copy of the Caelestia tokens: the greeter user cannot read
// ~/.local (Caelestia.Config plugin) nor the session config. scheme.json and
// greeter.json are written by scripts/caelestia-quiet.py.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("CAELESTIA_GREETER_DIR") || "/etc/greetd/caelestia"
    readonly property bool demo: Quickshell.env("CAELESTIA_GREETER_DEMO") === "1"

    property var scheme: ({})
    property var config: ({})

    readonly property var c: scheme.colours ?? ({})
    readonly property bool light: scheme.mode === "light"

    readonly property string user: config.user ?? "manu"
    readonly property string displayName: config.displayName ?? user
    readonly property string location: config.location ?? "41.60956,-4.79692"
    readonly property string wallpaper: `${dir}/wallpaper`
    readonly property string face: `${dir}/face`

    function col(key: string, fallback: string): color {
        const v = c[key];
        return v ? `#${v}` : fallback;
    }

    function term(i: int): color {
        return col(`term${i}`, ["#353434", "#ff8a7a", "#a6d189", "#e5c890", "#8caaee", "#f4b8e4", "#81c8be", "#c6d0f5"][i % 8]);
    }

    readonly property QtObject palette: QtObject {
        readonly property color m3surface: root.col("surface", "#16130f")
        readonly property color m3surfaceContainerLowest: root.col("surfaceContainerLowest", "#100e0b")
        readonly property color m3surfaceContainerLow: root.col("surfaceContainerLow", "#1e1b18")
        readonly property color m3surfaceContainer: root.col("surfaceContainer", "#221f1c")
        readonly property color m3surfaceContainerHigh: root.col("surfaceContainerHigh", "#2d2926")
        readonly property color m3surfaceContainerHighest: root.col("surfaceContainerHighest", "#383430")
        readonly property color m3onSurface: root.col("onSurface", "#e9e1dc")
        readonly property color m3onSurfaceVariant: root.col("onSurfaceVariant", "#d2c4b8")
        readonly property color m3outline: root.col("outline", "#9b8f84")
        readonly property color m3outlineVariant: root.col("outlineVariant", "#4e453c")
        readonly property color m3shadow: root.col("shadow", "#000000")
        readonly property color m3primary: root.col("primary", "#e4c09b")
        readonly property color m3onPrimary: root.col("onPrimary", "#422c11")
        readonly property color m3primaryContainer: root.col("primaryContainer", "#b99875")
        readonly property color m3onPrimaryContainer: root.col("onPrimaryContainer", "#473116")
        readonly property color m3secondary: root.col("secondary", "#d8c3ad")
        readonly property color m3onSecondary: root.col("onSecondary", "#3b2e21")
        readonly property color m3secondaryContainer: root.col("secondaryContainer", "#544739")
        readonly property color m3onSecondaryContainer: root.col("onSecondaryContainer", "#c8b5a4")
        readonly property color m3tertiary: root.col("tertiary", "#bccd9e")
        readonly property color m3onTertiary: root.col("onTertiary", "#283414")
        readonly property color m3tertiaryContainer: root.col("tertiaryContainer", "#879770")
        readonly property color m3onTertiaryContainer: root.col("onTertiaryContainer", "#1f2b0d")
        readonly property color m3error: root.col("error", "#ffb4ab")
        readonly property color m3onError: root.col("onError", "#690005")
        readonly property color m3errorContainer: root.col("errorContainer", "#93000a")
        readonly property color m3onErrorContainer: root.col("onErrorContainer", "#ffdad6")
    }

    readonly property QtObject rounding: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int largeIncreased: 20
        readonly property int extraLarge: 28
        readonly property int extraLargeIncreased: 32
        readonly property int extraExtraLarge: 48
        readonly property int full: 1000
    }

    readonly property QtObject spacing: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int largeIncreased: 20
        readonly property int extraLarge: 28
        readonly property int extraLargeIncreased: 32
        readonly property int extraExtraLarge: 48
    }

    readonly property QtObject durations: QtObject {
        readonly property int small: 200
        readonly property int normal: 400
        readonly property int large: 600
        readonly property int extraLarge: 1000
        readonly property int fastSpatial: 350
        readonly property int defaultSpatial: 500
        readonly property int slowSpatial: 650
        readonly property int fastEffects: 150
        readonly property int defaultEffects: 200
        readonly property int slowEffects: 300
    }

    readonly property QtObject curves: QtObject {
        readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property list<real> fastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
        readonly property list<real> defaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
        readonly property list<real> slowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]
        readonly property list<real> fastEffects: [0.31, 0.94, 0.34, 1, 1, 1]
        readonly property list<real> defaultEffects: [0.34, 0.8, 0.34, 1, 1, 1]
        readonly property list<real> slowEffects: [0.34, 0.88, 0.34, 1, 1, 1]
    }

    // Lock geometry: the greeter is the lock screen minus media/notifications.
    readonly property QtObject lock: QtObject {
        readonly property real heightMult: 0.7
        readonly property real ratio: 16 / 9
        readonly property int centerWidth: 600
        readonly property int showWeatherDetailsHeight: 550
        readonly property int showForecastHeight: 975
        readonly property int forecastItemWidth: 51
        readonly property int largeLogoWidth: 320
        readonly property int largeFontWidth: 400
        readonly property int fetch4LinesHeight: 600
        readonly property int fetch3LinesHeight: 500
        readonly property int showColourBoxRowHeight: 570
    }

    readonly property string sans: sansLoader.status === FontLoader.Ready ? sansLoader.name : "Google Sans Flex"
    readonly property string mono: "CaskaydiaCove NF"
    readonly property string icons: "Material Symbols Rounded"

    // Pixel sizes (px, not pt) so the layout does not depend on DPI.
    readonly property QtObject font: QtObject {
        readonly property int headlineLarge: 43
        readonly property int headlineMedium: 37
        readonly property int headlineSmall: 32
        readonly property int titleLarge: 29
        readonly property int titleMedium: 21
        readonly property int titleSmall: 19
        readonly property int bodyLarge: 21
        readonly property int bodyMedium: 19
        readonly property int bodySmall: 16
        readonly property int iconExtraLarge: 36
        readonly property int iconLarge: 24
        readonly property int iconMedium: 18
        readonly property int iconSmall: 15
    }

    FontLoader {
        id: sansLoader

        source: `file://${root.dir}/fonts/GoogleSansFlex.ttf`
    }

    FileView {
        path: `${root.dir}/scheme.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.scheme = JSON.parse(text());
            } catch (e) {
                console.warn(`greeter: bad scheme.json: ${e}`);
            }
        }
    }

    FileView {
        path: `${root.dir}/greeter.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.config = JSON.parse(text());
            } catch (e) {
                console.warn(`greeter: bad greeter.json: ${e}`);
            }
        }
    }
}
