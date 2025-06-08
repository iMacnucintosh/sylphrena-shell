<h1 align=center>caelestia-shell</h1>

<div align=center>
 
![GitHub last commit](https://img.shields.io/github/last-commit/caelestia-dots/shell?style=for-the-badge&labelColor=101418&color=9ccbfb)
![GitHub Repo stars](https://img.shields.io/github/stars/caelestia-dots/shell?style=for-the-badge&labelColor=101418&color=b9c8da)
![GitHub repo size](https://img.shields.io/github/repo-size/caelestia-dots/shell?style=for-the-badge&labelColor=101418&color=d3bfe6)
![Ko-Fi donate](https://img.shields.io/badge/donate-kofi?style=for-the-badge&logo=ko-fi&logoColor=ffffff&label=ko-fi&labelColor=101418&color=f16061&link=https%3A%2F%2Fko-fi.com%2Fsoramane)

</div>

https://github.com/user-attachments/assets/0840f496-575c-4ca6-83a8-87bb01a85c5f

## Components

- Widgets: [`Quickshell`](https://quickshell.outfoxxed.me)
- Window manager: [`Hyprland`](https://hyprland.org)
- Dots: [`caelestia`](https://github.com/caelestia-dots)

## Installation

### Automated installation (recommended)

Install [`caelestia-scripts`](https://github.com/caelestia-dots/scripts) and run `caelestia install shell`.

### Manual installation

Install all [dependencies](https://github.com/caelestia-dots/scripts/blob/main/install/shell.fish#L10), then
clone this repo into `$XDG_CONFIG_HOME/quickshell/caelestia` and run `qs -c caelestia`.

## Usage

All keybinds are accessible via Hyprland [global shortcuts](https://wiki.hyprland.org/Configuring/Binds/#dbus-global-shortcuts).
For a preconfigured setup, install [`caelestia-hypr`](https://github.com/caelestia-dots/hypr) via `caelestia install hypr` or see
[this file](https://github.com/caelestia-dots/hypr/blob/main/hyprland/keybinds.conf#L1-L29) for an example on how to use global
shortcuts.

There is only one IPC command as of now which can be used to get details about the currently active MPRIS player.
```sh
caelestia shell mpris getActive <prop>
```

## Credits

Thanks to the Hyprland discord community (especially the homies in #rice-discussion) for all the help and suggestions
for improving these dots!

A special thanks to [@outfoxxed](https://github.com/outfoxxed) for making Quickshell and the effort put into fixing issues
and implementing various feature requests.

Another special thanks to [@end_4](https://github.com/end-4) for his [config](https://github.com/end-4/dots-hyprland)
which helped me a lot with learning how to use Quickshell.

## Stonks 📈

<a href="https://www.star-history.com/#caelestia-dots/shell&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=caelestia-dots/shell&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=caelestia-dots/shell&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=caelestia-dots/shell&type=Date" />
 </picture>
</a>
