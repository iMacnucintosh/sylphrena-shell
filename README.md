<h1 align="center">Sylphrena</h1>

<p align="center"><strong>English</strong> · <a href="./README.es.md">Español</a></p>

<p align="center">
A complete <strong>Material You</strong> desktop for <a href="https://hypr.land">Hyprland</a>: bar, panels, activities, settings, login screen and its own apps, all with the same look.
</p>

<div align="center">

![Latest version](https://img.shields.io/github/v/tag/iMacnucintosh/sylphrena-shell?filter=v0.*&style=for-the-badge&labelColor=101418&color=9ccbfb&label=version)
![Last commit](https://img.shields.io/github/last-commit/iMacnucintosh/sylphrena-shell?style=for-the-badge&labelColor=101418&color=b9c8da&label=last%20change)

</div>

https://github.com/user-attachments/assets/1d005d8f-ab43-442d-a75a-917899f02845

## Installation

You need **Arch Linux**. From a terminal, as your user (not as root):

```sh
git clone https://github.com/iMacnucintosh/sylphrena-shell
cd sylphrena-shell
./install.sh
```

The installer looks at your system, shows what it is going to install and why, and **changes nothing until you confirm**. It asks for your password once, and installs Hyprland too if it is not there yet. When it finishes, log out (or reboot): you will come in through the Sylphrena login screen and, the first time, a welcome guide shows you the basics.

You can run it again whenever you want: it only does what is still missing. To see what it would do without changing anything, `./install.sh --dry-run`.

To update later, the shell offers new versions in its updates list (bar icon and Nexus → Updates); from a terminal, `sylph update`.

It compiles a few packages, so give it some time; on a machine with little memory (a 2 GB virtual machine, say) it compiles one thing at a time and takes longer.

<!-- screenshot: docs/media/installer.webp — the installer with its list of steps -->

## What it brings

### Activities

Group your desktops by context (for instance *Main*, *Games* and *Work*). Each activity has **its own wallpaper, colour scheme and light or dark mode**, and switching from one to another changes the look of the whole system. You can **pin apps** to a desktop so they always open there, and `Super+Tab` shows every activity at once so you can drag windows between them.

Transitions can be chosen too: by default, a vertical slide between desktops and a fade when you change activity.

<!-- screenshot: docs/media/activities.webp — the overview (Super+Tab) -->

### Bar and panels

A side bar with your desktops and the icons of their apps, the system tray, the clock and the indicators. The panels come out of the bar itself:

- **Dashboard** with the weather, media, how the computer is doing and a carousel of widgets (a calendar, plus whatever extensions add).
- **Side panel** with notifications and quick toggles (wifi, bluetooth, microphone, screen recording…).
- **App launcher** with search, a calculator and wallpapers.
- **Show desktop**: click the desktop you are already on and the windows slide away; click it again and they come back.

<!-- screenshot: docs/media/dashboard.webp — the dashboard open -->

### Nexus, the settings

Everything is set up from **Nexus** (`Super+,`), without editing files: activities and their look, panels, keyboard shortcuts (recorded by pressing the keys), network and VPN, bluetooth, audio, displays (resolution, refresh rate, scale and VRR), language, notifications and updates.

<!-- screenshot: docs/media/nexus.webp — Nexus on the Activities page -->

### System updates

When there are new packages (Arch, AUR or Flatpak), a notice shows up in the bar. From there or from Nexus you update with your password and watch the progress live, without opening a terminal.

<!-- screenshot: docs/media/updates.webp — the updates page with its progress -->

### Extensions and Things

Sylphrena grows with extensions (hydration, tasks, your Steam library with achievements and play time, a FortiClient VPN…). They are installed with one click from **Things**, the package manager that comes with Sylphrena, which also finds and installs programs from Arch, the AUR and Flatpak.

<!-- screenshot: docs/media/things.webp — Things on its Sylphrena section -->

### Apps that come with Sylphrena

- **[Things](https://github.com/iMacnucintosh/things)**: package and extension manager.
- **[Seeker](https://github.com/iMacnucintosh/seeker)**: file manager, with the same look as the shell.
- **kitty**: the terminal, which changes its colours with your activity.

GTK and Qt apps follow the colour scheme as well, and you can ask for some apps to always look light.

<!-- screenshot: docs/media/apps.webp — Seeker and Things next to the shell -->

### And also

- **Clipboard** with history, favourites, search and image previews (`Super+Shift+V`).
- **Screenshots and screen recording**, with an indicator in the bar while recording.
- **Lock screen** and **login screen** in the same style.
- Notifications, media controls, the audio profile of bluetooth headphones and *do not disturb*.
- In **English and Spanish**.

<!-- screenshot: docs/media/lock.webp — the lock screen -->

## Basic shortcuts

| Shortcut | What it does |
| --- | --- |
| `Super+Space` | App launcher |
| `Super+Q` | Terminal |
| `Super+E` | File manager |
| `Super+C` | Close the window |
| `Super+1` … `Super+0` | Go to a desktop |
| `Super+Ctrl+←` / `→` | Previous / next activity |
| `Super+Tab` | Overview of the activities |
| `Super+D` | Dashboard |
| `Super+,` | Nexus (settings) |
| `Super+Shift+V` | Clipboard |
| `Super+L` | Lock |
| `Print` | Screenshot of an area, to the clipboard |
| `Alt+Print` | Screenshot of an area, to edit it |

All of them can be changed in Nexus → Keyboard & mouse.

## More information

The detailed documentation is in Spanish for now:

| Document | Contents |
| --- | --- |
| [FEATURES.md](./FEATURES.md) | How to use every feature, in detail |
| [CONFIG.md](./CONFIG.md) | Every option of `shell.json` |
| [CHANGELOG.md](./CHANGELOG.md) | What changes in each version |
| [docs/DEVELOPMENT.md](./docs/DEVELOPMENT.md) | Manual installation, building from source and contributing |

Something does not work, or something is missing? [Open an issue](https://github.com/iMacnucintosh/sylphrena-shell/issues/new).

## Credits

Sylphrena started as a fork of [caelestia-shell](https://github.com/caelestia-dots/shell), by soramane, and today is a project of its own by [iMacnucintosh](https://github.com/iMacnucintosh). Thanks also to [Quickshell](https://github.com/outfoxxed/quickshell) ([@outfoxxed](https://github.com/outfoxxed)), which it is built on, and to [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) and [Ax-Shell](https://github.com/Axenide/Ax-Shell) for the inspiration.

Licensed under GPL-3.0.
