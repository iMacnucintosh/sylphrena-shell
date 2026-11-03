# Configuración (`shell.json`)

Referencia técnica de opciones. Cara pública: [README.md](./README.md). Guía de uso del fork: [FEATURES.md](./FEATURES.md).

El ejemplo JSON y la mayor parte del texto de esta página siguen en inglés (referencia heredada). Crea `~/.config/sylphrena/shell.json` solo con las claves que quieras cambiar.

## Opciones

All configuration options belong in `~/.config/sylphrena/shell.json`. This file is _not_ created by
default; you must create it manually. Options that you omit from the config file will use their default
values.

### Per-monitor configuration

You can configure per-monitor options in `~/.config/sylphrena/monitors/<monitor_name>/shell.json`.
List the names of your available monitors by running:

```sh
hyprctl monitors -j | jq -r '.[].name'
```

Options set in these files will **override** the respective options in the global config. Any options not present in
per-monitor configs will inherit their values from the global config.

For example, to automatically hide the bar on the monitor named `DP-1`:

**`~/.config/sylphrena/monitors/DP-1/shell.json`**

```json
{
    "bar": {
        "persistent": false
    }
}
```

> [!NOTE]
> Not all options respect per-monitor overrides. Most notably, the following options will only read
> from the global config, and ignore the respective option in per-monitor config files.
>
> <details><summary>Ignored options</summary>
>
> - `appearance`: `anim.*`, `transparency.*`
> - `bar.tray`: `hiddenIcons`, `iconSubs`
> - `bar.workspaces`: `ignoredTags`, `specialWorkspaceIcons`, `windowIcons`, `workspaceIcons`
> - `dashboard`: `mediaUpdateInterval`, `resourceUpdateInterval`
> - `general`: `apps.*`, `battery.*`, `idle.*`, `logo`
> - `launcher`: `actionPrefix`, `actions`, `enableDangerousActions`, `favouriteApps`, `hiddenApps`, `specialPrefix`, `useFuzzy.*`, `vimKeybinds`
> - `lock`: `enableFprint`, `enableHowdy`, `maxFprintTries`, `maxHowdyTries`, `triggerHowdyOnWake`
> - `nexus`: `networkRescanInterval`
> - `notifs`: `actionOnClick`, `defaultExpireTimeout`, `expire`, `fullscreen`, `fullscreenExpireTimeout`
> - `paths`: `lyricsDir`, `wallpaperDir`
> - `services`: `audioIncrement`, `brightnessIncrement`, `clockFormat`, `dataUnits`, `defaultPlayer`, `gpuType`, `lyricsBackend`, `maxVolume`, `playerAliases`, `sensorUnits`, `smartScheme`, `visualiserBars`, `weatherLocation`, `weatherUnits`
> - `utilities`: `toasts.*`, `vpn.*`
>
> </details>

### Example configuration

> [!WARNING]
> The example configuration includes **ALL** configuration options in `shell.json`. It is
> **not** recommended to copy and paste this entire configuration into `shell.json`,
> as options or their default values may change across updates, resulting in a stale config.
>
> This is meant to serve as a reference of all the available options, and you should
> <ins>only add the ones you want to change</ins> to `shell.json`.

<details><summary>Example config</summary>

```json
{
    "enabled": true,
    "appearance": {
        "deformScale": 1,
        "rounding": {
            "scale": 1
        },
        "spacing": {
            "scale": 1
        },
        "padding": {
            "scale": 1
        },
        "font": {
            "scale": 1,
            "clock": "Rubik",
            "workspaces": "Rubik",
            "headline": {
                "family": "GoogleSansFlex",
                "large": {
                    "size": 32,
                    "weight": 500,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                },
                "medium": {
                    "size": 28,
                    "weight": 500,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                },
                "small": {
                    "size": 24,
                    "weight": 500,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                }
            },
            "title": {
                "family": "GoogleSansFlex",
                "large": {
                    "size": 22,
                    "weight": 500,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                },
                "medium": {
                    "size": 16,
                    "weight": 500,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                },
                "small": {
                    "size": 14,
                    "weight": 500,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                }
            },
            "body": {
                "family": "GoogleSansFlex",
                "large": {
                    "size": 16,
                    "weight": 400,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                },
                "medium": {
                    "size": 14,
                    "weight": 400,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                },
                "small": {
                    "size": 12,
                    "weight": 400,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                }
            },
            "label": {
                "family": "GoogleSansFlex",
                "large": {
                    "size": 14,
                    "weight": 500,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                },
                "medium": {
                    "size": 12,
                    "weight": 500,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                },
                "small": {
                    "size": 11,
                    "weight": 400,
                    "italic": false,
                    "vaxes": { "ROND": 25 }
                }
            },
            "mono": {
                "family": "CaskaydiaCove NF",
                "large": {
                    "size": 16,
                    "weight": 400,
                    "italic": false,
                    "vaxes": {}
                },
                "medium": {
                    "size": 14,
                    "weight": 400,
                    "italic": false,
                    "vaxes": {}
                },
                "small": {
                    "size": 12,
                    "weight": 400,
                    "italic": false,
                    "vaxes": {}
                }
            },
            "icon": {
                "family": "Material Symbols Rounded",
                "extraLarge": {
                    "size": 36,
                    "weight": 400,
                    "italic": false,
                    "vaxes": {}
                },
                "large": {
                    "size": 24,
                    "weight": 400,
                    "italic": false,
                    "vaxes": {}
                },
                "medium": {
                    "size": 18,
                    "weight": 400,
                    "italic": false,
                    "vaxes": {}
                },
                "small": {
                    "size": 15,
                    "weight": 400,
                    "italic": false,
                    "vaxes": {}
                }
            }
        },
        "anim": {
            "durations": {
                "scale": 1
            }
        },
        "transparency": {
            "enabled": false,
            "base": 0.85,
            "layers": 0.4
        }
    },
    "general": {
        "logo": "",
        "showOverFullscreen": false,
        "mediaGifSpeedAdjustment": 300,
        "sessionGifSpeed": 0.7,
        "apps": {
            "terminal": ["foot"],
            "audio": ["pwvucontrol"],
            "playback": ["mpv"],
            "explorer": ["seeker"]
        },
        "idle": {
            "lockBeforeSleep": true,
            "inhibitWhenAudio": true,
            "inhibitWhenCharging": false,
            "timeouts": [
                {
                    "timeout": 180,
                    "idleAction": "lock",
                    "inhibitWhenAudio": false,
                    "inhibitWhenCharging": false,
                    "respectInhibitors": true
                },
                {
                    "timeout": 300,
                    "idleAction": "dpms off",
                    "returnAction": "dpms on"
                },
                {
                    "timeout": 600,
                    "idleAction": ["suspendThenHibernate"]
                }
            ]
        },
        "battery": {
            "warnLevels": [
                {
                    "level": 20,
                    "title": "Low battery",
                    "message": "You might want to plug in a charger",
                    "icon": "battery_android_frame_2"
                },
                {
                    "level": 10,
                    "title": "Did you see the previous message?",
                    "message": "You should probably plug in a charger <b>now</b>",
                    "icon": "battery_android_frame_1"
                },
                {
                    "level": 5,
                    "title": "Critical battery level",
                    "message": "PLUG THE CHARGER RIGHT NOW!!",
                    "icon": "battery_android_alert",
                    "critical": true
                }
            ],
            "criticalLevel": 3
        }
    },
    "background": {
        "enabled": true,
        "wallpaperEnabled": true,
        "desktopClock": {
            "enabled": false,
            "scale": 1.0,
            "position": "bottom-right",
            "invertColors": false,
            "background": {
                "enabled": false,
                "opacity": 0.7,
                "blur": true
            },
            "shadow": {
                "enabled": true,
                "opacity": 0.7,
                "blur": 0.4
            }
        },
        "visualiser": {
            "enabled": false,
            "autoHide": true,
            "blur": false,
            "rounding": 1,
            "spacing": 1
        }
    },
    "bar": {
        "persistent": true,
        "showOnHover": true,
        "dragThreshold": 20,
        "scrollActions": {
            "workspaces": true,
            "volume": true,
            "brightness": true
        },
        "popouts": {
            "activeWindow": true,
            "tray": true,
            "statusIcons": true
        },
        "workspaces": {
            "shown": 5,
            "activeIndicator": true,
            "occupiedBg": false,
            "showUnoccupied": true,
            "perMonitor": true,
            "showWindows": true,
            "showWindowsOnSpecialWorkspaces": true,
            "maxWindowIcons": 5,
            "activeTrail": false,
            "displayType": "shapes",
            "specialDisplayType": "icons",
            "label": "  ",
            "occupiedLabel": "󰮯",
            "activeLabel": "󰮯",
            "capitalisation": "preserve",
            "workspaceIcons": [],
            "specialWorkspaceIcons": [
                {
                    "name": "special",
                    "icon": "star"
                },
                {
                    "name": "communication",
                    "icon": "forum"
                },
                {
                    "name": "music",
                    "icon": "music_cast"
                },
                {
                    "name": "todo",
                    "icon": "checklist"
                },
                {
                    "name": "sysmon",
                    "icon": "monitor_heart"
                }
            ],
            "ignoredTags": ["hide_in_bar", "xwl_popup"],
            "windowIcons": [
                {
                    "regex": "steam(_app_(default|[0-9]+))?",
                    "icon": "sports_esports"
                }
            ]
        },
        "activeWindow": {
            "compact": false,
            "inverted": false,
            "showOnHover": true
        },
        "tray": {
            "background": false,
            "recolour": false,
            "compact": false,
            "iconSubs": [],
            "hiddenIcons": []
        },
        "clock": {
            "background": false,
            "showDate": false,
            "showIcon": true
        },
        "statusIcons": [
            {
                "id": "lockStatus",
                "enabled": true
            },
            {
                "id": "audio",
                "enabled": false
            },
            {
                "id": "microphone",
                "enabled": false
            },
            {
                "id": "kbLayout",
                "enabled": false
            },
            {
                "id": "network",
                "enabled": true
            },
            {
                "id": "bluetooth",
                "enabled": true
            },
            {
                "id": "vpn",
                "enabled": true
            },
            {
                "id": "battery",
                "enabled": true
            }
        ],
        "entries": [
            {
                "id": "logo",
                "enabled": true
            },
            {
                "id": "workspaces",
                "enabled": true
            },
            {
                "id": "spacer",
                "enabled": true
            },
            {
                "id": "activeWindow",
                "enabled": true
            },
            {
                "id": "spacer",
                "enabled": true
            },
            {
                "id": "tray",
                "enabled": true
            },
            {
                "id": "clock",
                "enabled": true
            },
            {
                "id": "statusIcons",
                "enabled": true
            },
            {
                "id": "power",
                "enabled": true
            }
        ],
        "excludedScreens": []
    },
    "border": {
        "thickness": 10,
        "rounding": 25,
        "smoothing": 20
    },
    "dashboard": {
        "enabled": true,
        "showOnHover": true,
        "showDashboard": true,
        "showMedia": true,
        "showPerformance": true,
        "showWeather": true,
        "mediaUpdateInterval": 500,
        "resourceUpdateInterval": 1000,
        "dragThreshold": 50,
        "performance": {
            "showBattery": true,
            "showGpu": true,
            "showCpu": true,
            "showMemory": true,
            "showStorage": true,
            "showNetwork": true
        }
    },
    "launcher": {
        "enabled": true,
        "showOnHover": false,
        "maxShown": 7,
        "maxWallpapers": 9,
        "specialPrefix": "@",
        "actionPrefix": ">",
        "enableDangerousActions": false,
        "dragThreshold": 50,
        "vimKeybinds": false,
        "favouriteApps": [],
        "hiddenApps": [],
        "useFuzzy": {
            "apps": false,
            "actions": false,
            "schemes": false,
            "variants": false,
            "wallpapers": false
        },
        "actions": [
            {
                "name": "Calculator",
                "icon": "calculate",
                "description": "Do simple math equations (powered by Qalc)",
                "command": ["autocomplete", "calc"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Scheme",
                "icon": "palette",
                "description": "Change the current colour scheme",
                "command": ["autocomplete", "scheme"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Wallpaper",
                "icon": "image",
                "description": "Change the current wallpaper",
                "command": ["autocomplete", "wallpaper"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Variant",
                "icon": "colors",
                "description": "Change the current scheme variant",
                "command": ["autocomplete", "variant"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Random",
                "icon": "casino",
                "description": "Switch to a random wallpaper",
                "command": ["sylphrena", "wallpaper", "-r"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Light",
                "icon": "light_mode",
                "description": "Change the scheme to light mode",
                "command": ["setMode", "light"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Dark",
                "icon": "dark_mode",
                "description": "Change the scheme to dark mode",
                "command": ["setMode", "dark"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Shutdown",
                "icon": "power_settings_new",
                "description": "Shutdown the system",
                "command": ["poweroff"],
                "enabled": true,
                "dangerous": true
            },
            {
                "name": "Reboot",
                "icon": "cached",
                "description": "Reboot the system",
                "command": ["reboot"],
                "enabled": true,
                "dangerous": true
            },
            {
                "name": "Logout",
                "icon": "exit_to_app",
                "description": "Log out of the current session",
                "command": ["logout"],
                "enabled": true,
                "dangerous": true
            },
            {
                "name": "Lock",
                "icon": "lock",
                "description": "Lock the current session",
                "command": ["loginctl", "lock-session"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Sleep",
                "icon": "bedtime",
                "description": "Suspend then hibernate",
                "command": ["suspendThenHibernate"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Settings",
                "icon": "settings",
                "description": "Configure the shell",
                "command": ["sylphrena", "shell", "nexus", "open"],
                "enabled": true,
                "dangerous": false
            }
        ]
    },
    "lock": {
        "enabled": true,
        "useWallpaper": false,
        "recolourLogo": true,
        "enableFprint": true,
        "maxFprintTries": 3,
        "enableHowdy": true,
        "maxHowdyTries": 3,
        "triggerHowdyOnWake": true,
        "hideNotifs": false,
        "enableSessionControls": true
    },
    "nexus": {
        "wallpapersPerRow": 4,
        "networkRescanInterval": 15000
    },
    "notifs": {
        "expire": true,
        "fullscreen": "On",
        "defaultExpireTimeout": 5000,
        "fullscreenExpireTimeout": 2000,
        "clearThreshold": 0.3,
        "expandThreshold": 20,
        "actionOnClick": false,
        "groupPreviewNum": 3,
        "openExpanded": false
    },
    "osd": {
        "enabled": true,
        "hideDelay": 2000,
        "enableBrightness": true,
        "enableMicrophone": false
    },
    "services": {
        "weatherLocation": "",
        "weatherUnits": "Auto",
        "sensorUnits": "Celsius",
        "dataUnits": "Binary",
        "clockFormat": "Auto",
        "gpuType": "Auto",
        "visualiserBars": 60,
        "audioIncrement": 0.1,
        "brightnessIncrement": 0.1,
        "maxVolume": 1.0,
        "smartScheme": true,
        "defaultPlayer": "Spotify",
        "playerAliases": [
            { "from": "com.github.th_ch.youtube_music", "to": "YT Music" }
        ],
        "lyricsBackend": "Auto"
    },
    "session": {
        "enabled": true,
        "dragThreshold": 30,
        "vimKeybinds": false,
        "icons": {
            "logout": "logout",
            "shutdown": "power_settings_new",
            "suspend": "bedtime",
            "reboot": "cached"
        },
        "commands": {
            "logout": ["logout"],
            "shutdown": ["poweroff"],
            "suspend": ["suspend"],
            "reboot": ["reboot"]
        }
    },
    "sidebar": {
        "enabled": true,
        "showOnHover": false,
        "minHoverThreshold": 200,
        "dragThreshold": 80
    },
    "utilities": {
        "enabled": true,
        "maxToasts": 4,
        "toasts": {
            "fullscreen": "off",
            "configLoaded": true,
            "chargingChanged": true,
            "gameModeChanged": true,
            "dndChanged": true,
            "audioOutputChanged": true,
            "audioInputChanged": true,
            "capsLockChanged": true,
            "numLockChanged": true,
            "kbLayoutChanged": true,
            "kbLimit": true,
            "vpnChanged": true,
            "nowPlaying": false
        },
        "vpn": {
            "enabled": false,
            "provider": [
                {
                    "name": "wireguard",
                    "interface": "your-connection-name",
                    "displayName": "Wireguard (Your VPN)",
                    "enabled": false
                }
            ]
        },
        "quickToggles": [
            {
                "id": "wifi",
                "enabled": true
            },
            {
                "id": "bluetooth",
                "enabled": true
            },
            {
                "id": "mic",
                "enabled": true
            },
            {
                "id": "settings",
                "enabled": true
            },
            {
                "id": "gameMode",
                "enabled": true
            },
            {
                "id": "dnd",
                "enabled": true
            },
            {
                "id": "vpn",
                "enabled": false
            }
        ]
    },
    "paths": {
        "wallpaperDir": "~/Pictures/Wallpapers",
        "lyricsDir": "~/Music/lyrics/",
        "sessionGif": "root:/assets/kurukuru.gif",
        "mediaGif": "root:/assets/bongocat.gif",
        "noNotifsPic": "root:/assets/dino.png",
        "lockNoNotifsPic": "root:/assets/dino.png"
    }
}
```

</details>

### Advanced configuration

> [!CAUTION]
> Do NOT change any of these options unless you know what you are doing. These options control the
> tokens used internally within the shell, and can cause visual issues if modified incorrectly.
> The available options may change or be removed without notice across versions.

A separate `~/.config/sylphrena/shell-tokens.json` file allows editing the internal tokens without
touching the source code of the shell. These tokens affect the dimensions and appearance of visual elements,
including individual rounding, spacing, padding, font size, animation durations and curves, and the sizes of
certain components. The appearance scale values in `shell.json` are multiplied against these base
token values to produce the final computed values.

Per-monitor token overrides are also available at
`~/.config/sylphrena/monitors/<monitor_name>/shell-tokens.json`.

