<h1 align="center">Sylphrena</h1>

<p align="center">
Shell de escritorio <strong>Material You</strong> para <a href="https://hypr.land">Hyprland</a>, hecha con <a href="https://quickshell.outfoxxed.me">Quickshell</a> / QML.<br/>
CLI: <code>sylph</code> · instancia: <code>qs -c sylphrena</code> · config Lua de Hyprland.
</p>

<p align="center">
Fork de <a href="https://github.com/caelestia-dots/shell">caelestia-shell</a> (soramane), rebranded y ampliado.<br/>
Repo: <a href="https://github.com/iMacnucintosh/sylphrena-shell">iMacnucintosh/sylphrena-shell</a> · tags propios <code>v0.*</code>
</p>

<div align="center">

![GitHub last commit](https://img.shields.io/github/last-commit/iMacnucintosh/sylphrena-shell?style=for-the-badge&labelColor=101418&color=9ccbfb)
![GitHub Repo stars](https://img.shields.io/github/stars/iMacnucintosh/sylphrena-shell?style=for-the-badge&labelColor=101418&color=b9c8da)
![GitHub repo size](https://img.shields.io/github/repo-size/iMacnucintosh/sylphrena-shell?style=for-the-badge&labelColor=101418&color=d3bfe6)

</div>

https://github.com/user-attachments/assets/0840f496-575c-4ca6-83a8-87bb01a85c5f

## Funcionalidades

### Activities

- Espacios de trabajo agrupados (p. ej. Principal, Juegos, Trabajo) con **pills** en la barra.
- **Overview** a pantalla completa (`Super+Tab`): drag & drop de ventanas entre desktops/actividades; pins no se arrastran.
- **Look por actividad**: wallpaper, esquema, modo claro/oscuro, transparencia y light apps (apply atómico).
- Apps **ancladas** por desktop (reglas Hyprland generadas).
- Atajos `Super+Ctrl+←/→` y opción de saltar entre actividades.

### Barra y paneles

- Tray / status con pastilla unificada al hover; trays Electron/Flatpak sobreviviendo a reinicios de la shell.
- Indicador **REC** / **PAUSE** bajo el reloj; grabación desacoplada del panel.
- **Clipboard** (cliphist): `Super+Shift+V`, favoritos, previews, pegar en la ventana enfocada.
- **Updates** (Arch / AUR / Flatpak): badge solo si hay paquetes, popout y página Nexus; update en segundo plano con password en RAM.
- **VPN FortiClient** (opt-in): OTP en popout, settings, heal tras suspender.
- Popouts, toasts en borde (posición superior/inferior) y now playing con portada animada.

### Nexus

- Página **Activities** (comportamiento + look; Principal = look general heredable).
- **Complementos**: VPN, Timers, Hidratación, Juegos/Steam, Clipboard — on/off con limpieza al desactivar.
- **Pantalla** inline en Dispositivos conectados: resolución, Hz, escala y VRR (Nunca / Automático / Siempre) por monitor.
- Atajos remapeables (incl. F13–F35), última ventana, foco al hover o al clic.
- Sidebar por categorías; saltos por `id` estable; **i18n español** completo.

### Dashboard y lock

- Pestaña **Juegos** (Steam opt-in): stats Material You, logros, heatmap, no-Steam / Millennium, caché en disco.
- **Hidratación** (opt-in): depósito con waves, meta diaria, recordatorio.
- Timers del reloj persistentes (presets + duración manual + sonido).
- **Lock**: notificaciones con scroll (35 %) + compañera Sylphrena (65 %); orbe SoftBurst compartido con el greeter.
- **Greeter** Material You (greetd) instalable con un solo `sudo`.

### Theming y apps

- Kitty, GTK/Seeker, qt6ct y Papirus alineados al esquema de la actividad (`sylphrena-quiet`).
- Explorador por defecto **Seeker**; Thunar como fallback.
- Layout **compacto** (barra izquierda, gaps/rounding/border a 0).
- Keep-awake (café) por defecto, persistente entre reinicios de la shell.
- Launcher con hover inferior y edición de `.desktop`.

### Base (heredada de caelestia)

Launcher, dashboard, utilities, notificaciones, media/MPRIS, lock PAM, switcher de wallpapers/esquemas, IPC vía CLI, y el resto del shell Quickshell Material You.

---

## Documentación

| Documento | Contenido |
| --- | --- |
| **[FEATURES.md](./FEATURES.md)** | Guía detallada de uso del fork |
| **[CHANGELOG.md](./CHANGELOG.md)** | Cambios recientes |
| **[CONFIG.md](./CONFIG.md)** | Referencia de `shell.json` / tokens |
| **[AGENTS.md](./AGENTS.md)** | Mapa para agentes/devs (convenciones, trampas, roadmap) |

---

## Instalación

> [!NOTE]
> Hay PKGBUILD de los cuatro paquetes (`sylphrena-shell-git`, `sylphrena-cli-git`, `seeker-git`, `things-git`, en el `packaging/` de cada repo; ver [`packaging/README.md`](packaging/README.md)). **La publicación en el AUR está pendiente**: hasta entonces se instalan con `makepkg -si` desde un clon, o con el flujo de abajo (clone + build user-local del plugin C++).

### Dependencias

Runtime / sistema (Arch):

- [`quickshell-git`](https://git.outfoxxed.me/quickshell/quickshell) (versión git, no solo el tag estable)
- CLI **`sylph`** (paquete `sylphrena-cli-git`, ver `packaging/`; o el binario user-local en `~/.local/bin`)
- `ddcutil`, `brightnessctl`, `libcava`, `networkmanager`, `lm_sensors`, `aubio`, `libpipewire`, `libqalculate`, `power-profiles-daemon`
- Fuentes: `ttf-material-symbols-variable`, `ttf-rubik-vf`, `ttf-cascadia-code-nerd`
- Qt 6: `qt6-base`, `qt6-declarative`, `qt6-imageformats`, `qt6-multimedia`, [`qt6-m3shapes-git`](https://github.com/soramanew/m3shapes)
- `swappy`, `fish`, `bash`
- Clipboard: `cliphist`, `wl-clipboard`, `wtype`
- Hyprland + portales (`xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`), `qt6ct`, tema de iconos Papirus (recomendado)

Build: `cmake`, `ninja`, `qt6-shadertools`.

Opcionales según complementos: `yay` (updates AUR), Flatpak, `openfortivpn` (VPN FortiClient), Steam, Blender (+ `.thumbnailer` local; Arch no lo registra en el paquete).

### Clone

El código que **corre** es el checkout (no un paquete en `/etc/xdg`):

```sh
mkdir -p ~/.config/quickshell
git clone https://github.com/iMacnucintosh/sylphrena-shell.git ~/.config/quickshell/sylphrena
cd ~/.config/quickshell/sylphrena
```

### Plugin C++ (user-local)

```sh
cmake -B build -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_MODULES=plugin \
  -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build build
cmake --install build   # sin sudo; instala en ~/.local
```

Con `ENABLE_MODULES=plugin` **no** se sobrescribe `shell.qml`. La shell carga el plugin vía
`QT_ADDITIONAL_PACKAGES_PREFIX_PATH` en `shell.qml` → `~/.local/lib/qt6/qml`.

Tras cambios de i18n, recompila e instala el mismo módulo.

### Hyprland

En tu config Lua:

```lua
require("sylphrena-binds")            -- atajos (Nexus → Keyboard & mouse)
require("sylphrena-activity-rules")   -- activities / pins
require("sylphrena-monitors")         -- VRR / modos (Nexus → Pantalla)
-- require("sylphrena-input")         -- follow_mouse (si lo usas desde Nexus)
```

Arranque recomendado (watcher SNI + shell): `scripts/start-shell-with-tray-watcher.sh`
(o equivalente en tu `hyprland.lua`). El PATH del compositor a menudo **no** incluye `~/.local/bin`; usa ruta absoluta a `sylph` si hace falta.

### Greeter (opcional)

```sh
./scripts/install-system.sh   # un solo prompt de root; greeter Material You + drop-ins logind
```

### Arranque

```sh
sylph shell -d          # detach
sylph shell -r          # reiniciar tras cambios QML
# equivalente: qs -c sylphrena -n -d
```

Runtime de config: `~/.config/sylphrena/` (`shell.json`, `keybinds.json`, `cli.json`, `templates/`).
Estado: `~/.local/state/sylphrena/`.

---

## Uso rápido

```sh
sylph shell -s                          # IPC disponibles
sylph wallpaper -f ~/Imágenes/foo.jpg
sylph scheme set -n dynamic
```

- Avatar del dashboard: `~/.face` (o clic en el dashboard).
- Wallpapers del launcher: `~/Imágenes` / `paths.wallpaperDir` en `shell.json` (por defecto `~/Pictures/Wallpapers` en configs en inglés).
- Cada **activity** puede guardar su propio wallpaper/esquema; al cambiar de activity se reaplica el look.

Detalle de cada feature: **[FEATURES.md](./FEATURES.md)**. Opciones: **[CONFIG.md](./CONFIG.md)**.

---

## Actualizar

```sh
cd ~/.config/quickshell/sylphrena
git pull
# si cambió el plugin C++ / i18n:
cmake --build build && cmake --install build
sylph shell -r
```

---

## FAQ breve

**¿Cómo desactivo una feature?**  
Complementos on/off en Nexus, o la clave correspondiente en [`CONFIG.md`](./CONFIG.md) / `shell.json`. Si no hay opción: [issue](https://github.com/iMacnucintosh/sylphrena-shell/issues/new).

**¿El esquema no sigue al wallpaper?**  
`sylph wallpaper -f …` y `sylph scheme set -n dynamic`, o el look de cada activity en Nexus → Activities.

**¿No veo wallpapers en el launcher?**  
Revisa `paths.wallpaperDir`. El grid del launcher muestra un número impar de miniaturas.

**¿Los trays (Teams, etc.) desaparecen tras `sylph shell -r`?**  
El StatusNotifierWatcher debe vivir fuera de `qs` (`scripts/status-notifier-watcher.py` vía `start-shell-with-tray-watcher.sh`).

---

## Créditos

- Base: [caelestia-shell](https://github.com/caelestia-dots/shell) — soramane
- [Quickshell](https://github.com/outfoxxed/quickshell) — [@outfoxxed](https://github.com/outfoxxed)
- Inspiración de aprendizaje: [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland), [Axenide/Ax-Shell](https://github.com/Axenide/Ax-Shell)
- Comunidad Hyprland (#rice-discussion)

Sylphrena (fork, greeter, Activities, complementos, i18n ES, Seeker, etc.): [iMacnucintosh](https://github.com/iMacnucintosh).
