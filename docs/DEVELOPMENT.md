# Desarrollo e instalación manual

Para usar Sylphrena basta con el instalador del [README](../README.md). Esta guía es para trabajar sobre el código: instalarlo a mano, compilar el plugin, engancharlo a Hyprland y actualizar desde un clon. El mapa del código, las convenciones y las trampas conocidas están en [AGENTS.md](../AGENTS.md).

## Dependencias

Runtime (Arch):

- [`quickshell-git`](https://git.outfoxxed.me/quickshell/quickshell) (la versión git, no solo el tag estable)
- CLI **`sylph`** (paquete `sylphrena-cli-git`, o el binario user-local en `~/.local/bin`)
- `brightnessctl`, `libcava`, `networkmanager`, `lm_sensors`, `aubio`, `libpipewire`, `libqalculate`, `power-profiles-daemon`; `ddcutil` para el brillo de monitores externos
- Fuentes: `ttf-material-symbols-variable`, `ttf-rubik-vf`, `ttf-cascadia-code-nerd`
- Qt 6: `qt6-base`, `qt6-declarative`, `qt6-imageformats`, `qt6-multimedia`, [`qt6-m3shapes-git`](https://github.com/soramanew/m3shapes)
- `swappy`, `fish`, `bash`
- Portapapeles: `cliphist`, `wl-clipboard`, `wtype`
- Hyprland y portales (`xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`), `qt6ct`, `papirus-icon-theme` y `adw-gtk-theme` (la shell escribe su configuración)

Compilación: `cmake`, `ninja`, `qt6-shadertools`.

Opcionales: `yay` (actualizaciones del AUR), Flatpak, `gpu-screen-recorder` (grabar pantalla), `greetd` (pantalla de inicio de sesión), y lo que pida cada extensión.

Hay PKGBUILD de los cuatro paquetes (`sylphrena-shell-git`, `sylphrena-cli-git`, `seeker-git`, `things-git`) en el `packaging/` de cada repo; ver [`packaging/README.md`](../packaging/README.md). La publicación en el AUR está pendiente.

## Instalar desde un clon

El código que corre es el checkout:

```sh
mkdir -p ~/.config/quickshell
git clone https://github.com/iMacnucintosh/sylphrena-shell.git ~/.config/quickshell/sylphrena
cd ~/.config/quickshell/sylphrena
```

### Plugin C++ (en tu usuario, sin sudo)

```sh
cmake -B build -UVERSION -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_MODULES=plugin \
  -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build build
cmake --install build
```

Con `ENABLE_MODULES=plugin` no se sobrescribe `shell.qml`. `sylph shell` exporta `QT_ADDITIONAL_PACKAGES_PREFIX_PATH=~/.local/lib/qt6/qml` para que se cargue este plugin y no el del sistema. Las traducciones viven en el plugin: tras tocar `es.po`, recompila e instala.

`-UVERSION` importa: la versión que la shell anuncia (y con la que se comprueban las extensiones) sale del último tag `v0.*`, y un `-DVERSION` fijo en la caché de CMake la congelaría.

### Hyprland

`scripts/setup-hyprland.py` añade a `~/.config/hypr/hyprland.lua` un bloque marcado con el arranque de la shell, `QT_QPA_PLATFORMTHEME` y los ficheros que Sylphrena genera desde Nexus (con copia de seguridad y validación). A mano, sería:

```lua
pcall(require, "sylphrena-binds")            -- atajos (Nexus → Teclado y ratón)
pcall(require, "sylphrena-activity-rules")   -- actividades y apps ancladas
pcall(require, "sylphrena-monitors")         -- modos y VRR (Nexus → Pantalla)
pcall(require, "sylphrena-input")            -- foco del ratón
pcall(require, "sylphrena-animation")        -- transiciones (después de tus animaciones)
```

Para arrancar, `scripts/start-shell-with-tray-watcher.sh`: deja vivo el watcher de la bandeja del sistema aunque reinicies la shell (si no, los iconos de apps Electron o Flatpak desaparecen tras `sylph shell -r`). El `PATH` del compositor no suele incluir `~/.local/bin`: usa rutas absolutas.

### Pantalla de inicio de sesión

```sh
./scripts/install-system.sh   # pide root una vez; greetd + greeter Material You + ajustes de logind
```

## Arrancar y actualizar

```sh
sylph shell -d     # en segundo plano
sylph shell -r     # reiniciar tras cambios en QML
```

```sh
cd ~/.config/quickshell/sylphrena
git pull
cmake --build build && cmake --install build   # si cambió el plugin C++ o las traducciones
sylph shell -r
```

Configuración: `~/.config/sylphrena/` (`shell.json`, `keybinds.json`, `cli.json`). Estado: `~/.local/state/sylphrena/`.

## Antes de mandar un cambio

- Tests: `cd tests && python3 -m unittest -q`.
- Textos: todo lo visible pasa por `Tr.tr` y se traduce en `plugin/src/Sylphrena/I18n/trs/es.po` (`fish scripts/trs.fish raw` + `msgmerge`, sin cadenas sin traducir ni `fuzzy`; `python3 scripts/trs-check.py`).
- Commits con *conventional commits* (`feat:`, `fix:`, `docs:`) y PR contra `main`.
