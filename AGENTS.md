# AGENTS.md — Referencia del fork

Punto de referencia para cualquier agente/IDE/modelo que entre sin contexto. Si cambias algo respecto
a este fichero, **actualízalo en el mismo commit**. Detalle de uso en [FEATURES.md](./FEATURES.md),
cambio a cambio en [CHANGELOG.md](./CHANGELOG.md), instalación/config upstream en [README.md](./README.md).

---

## 1. Qué es

- Fork rebranded como **Sylphrena** (shell Quickshell/QML para **Hyprland**, config en **Lua**). CLI: `sylph` (paquete user-local `sylphrena-cli`); instancia Quickshell `qs -c sylphrena`. El directorio es `~/.config/quickshell/sylphrena`.
- Repo GitHub: **iMacnucintosh/sylphrena-shell**. Remote `origin` = tu fork; `upstream` = el proyecto original (crédito en el README). Las actualizaciones de base se hacen mergeando upstream y pasando PR a `main`.
- Versión propia: tags `v0.*` (`v0.1.0` es la primera). CMake usa `git describe --match v0.*`. Los tags `v1.*` y `v2.*` son del proyecto original y no cuentan; al salir de 0.x hay que ampliar el `--match`, porque `v1.0.0` ya existe en el historial.
- El código que **corre** es este checkout: `~/.config/quickshell/sylphrena` (no el paquete AUR de `/etc/xdg`). El plugin C++ de config se compila **desde la raíz del repo** e instala en `~/.local` (sin sudo); `shell.qml` lo carga vía pragma `QT_ADDITIONAL_PACKAGES_PREFIX_PATH` — ver "Plugin C++ (build user-local)" en FEATURES.md.
- Runtime de la shell: `~/.config/sylphrena/` (`shell.json`, `keybinds.json`, `cli.json`, `templates/`). El plugin escribe `/sylphrena` (config, state, cache, runtime).
- Estado persistente: `~/.local/state/sylphrena/` (`timers.json`, `hydration.json`, `light-apps.json`, `nonsteam-sessions.json`, `steam-activity.json`, `steam-achievements-cache.json`, `sequences.txt`, `theme/kitty.conf`).
- Generados por el fork en Hyprland (todos via `require(...)` desde `hyprland.lua`): `sylphrena-binds.lua`, `sylphrena-activity-rules.lua`, `sylphrena-monitors.lua`.

## 2. Entorno del usuario (Manu)

- Arch Linux + **Hyprland 0.57**, sobremesa (sin batería), monitor MSI 1440p @ **144 Hz** por HDMI (`HDMI-A-1`).
- Login: **greetd + greeter Quickshell Material You** tras logout (autologin inicial a `start-hyprland`; teclado `es`, cortina negra + VT limpio y watchdog anti-stuck). Hyprland de usuario va por `quiet-exec` (sin TTY, log en `~/.local/state/sylphrena/session-startup.log`). El compositor desechable hace `hyprctl exit` corto + SIGKILL y deja tty1 en modo texto. `logind` `UserStopDelaySec=0` + `user@.service` `TimeoutStopSec=8`. Instalación con `greeter/install-greeter.sh`. Plasma y plasmalogin ya no están. Cursor **Adwaita** en GTK/Qt/Hyprland.
- Locale `es_ES.UTF-8`; **todo lo nuevo va con i18n**: cadenas vía `Tr.tr` / `Tr.trN` / `Tr.trCtx` → `es.po` → recompilar el plugin I18n e instalarlo en `~/.local`.
- Apps por defecto: **kitty** (terminal), **thunar** (explorador, `Super+E`, sirve `FileManager1` vía override D-Bus), tema de iconos **Papirus(-Dark)**. Vídeo: sin reproductor (`general.apps.playback` vacío; VLC se desinstaló el 2026-10-30).
- Qt platform theme: **qt6ct** (`~/.config/qt6ct`, paleta + Papirus los empuja `sylphrena-quiet` en cada esquema). Plasma desinstalado (fase 2, 2026-10-30).
- VPN del trabajo: openfortivpn (credenciales **solo** en `~/.config/openfortivpn/config`, jamás en el repo).
- Steam: API key **solo en config local** (nunca commitearla; grep del diff antes de push). Perfil/logros públicos.
- OpenCode TUI: plugin sidebar file-tree es un **fork local** en `~/.config/opencode/plugins/opencode-file-tree` (colores git en el árbol; rebuild con `bun run build`, no npm; verificación en su `test.md`). El tema del TUI (`sylphrena` + gemela `sylphrena-alt` para el hot-reload por flip de nombre) lo genera `scripts/generate-opencode-theme.py` y lo engancha `sylphrena-quiet.py`.

## 3. Convenciones de trabajo

- Tras cualquier cambio de QML/script: **reiniciar la shell** (`sylph shell -r`; background `-r -d`) y verificar que carga sin errores. Hyprland arranca con `/home/manu/.local/bin/sylph shell -d` (el PATH del compositor no tiene `~/.local/bin`).
- Cualquier `sh -c`/`bash -c` que lleve contenido de usuario va **por argv (`"$1"`)**: `JSON.stringify` es quoting de JS, no de shell (lección: inyección en Clipboard). Contraseñas/secretos nunca a fichero: en RAM con `sudo -S -v` por paso (ver `scripts/run-system-update.sh`).
- Estilo **Material You estricto**: tokens, `MaterialShape`, blur/transparencia; los detalles visuales (padding, tamaños, sombras, centrados) se afinan con el usuario tras cada versión — espera feedback visual.
- Commits: **conventional commits** (`feat:` / `fix:` / `docs:`), a nombre del usuario. **NUNCA** dejar trailer `Co-authored-by: Cursor/agent`.
- Commits **locales por defecto**: el agente commitea a menudo, en commits agrupados, ordenados y bien explicados, pero **NO pushea a `origin`** — el usuario indica cuándo hacer push.
- `main` está **protegida** (toda escritura exige PR). Flujo: rama `feature/*` o `docs/*` + PR (vía `gh`, HTTPS), y merge de la PR. El push directo a `main` lo rechazan las rules del repo (GH013).
- `.gitignore` cubre `__pycache__/` y `.cursor-tmp/`.
- Opciones nuevas: nodo en config (GlobalConfig) si hace falta rebuild del plugin, exposición en Nexus, y **documentación en FEATURES.md**.
- Nexus: `PageRegistry` lleva `id` estable por página — saltos programáticos usan `idxOf(id)`, jamás índices hardcodeados; el look global **es** el estilo de Principal (nunca nodos globales sueltos ni páginas duplicadas). El auto-ocultado de updates/VPN es config real (`bar.status`); batería y reloj quedaron **vanilla** (ocultar por lista de statusIcons; popout/fondo del reloj como upstream salvo la pastilla de hover que abre su popout).

## 4. Mapa del código

### Servicios (`services/`, singletons QML)
| Servicio | Qué hace |
| --- | --- |
| `Activities` | Core del fork: pills en la barra, look por activity, apply atómico vía `scripts/apply-activity-style.py` (wallpaper + un solo `scheme set`; el modo de la activity gana a `smartScheme`; verify + reintentos). El apply es **serial**: lanzar en paralelo = carrera light/dark |
| `Colours` | Paleta, modo light/dark, `lightApps` (portal `prefer-light`; theming GTK off con light apps sin que pierda el CSS del esquema) |
| `Steam` | Façade singleton (~370 líneas) + `services/steam/*` (Format, Api, Library, Achievements, Local, Activity). Web API + logros (caché disco TTL ~1d) + no-Steam (VDF/Millennium) + sesiones (`reaper`). Al refrescar **conserva el juego seleccionado**; `gen` compartido |
| `Updates` | Poll 30 min (Arch/AUR/Flatpak); update: password popup → `sudo -S -v` de comprobación → script en bg con askpass **en RAM** (helper + socket, sin fichero). Nunca `yay --sudoloop` (bloquea con faillock). yay/pacman con `--sudoflags=-A` / `sudo -A`; no usar `-n` (el timestamp de sudo es por TTY y el Process no tiene TTY) |
| `Clipboard` | cliphist + `wl-clipboard`; paste con foco restaurado (~220 ms) + `send_shortcut` / `wtype` |
| `MadisonVpn` | Status exige ping a intranet (no basta `ppp0`); teardown/heal tras suspender; popout OTP + settings |
| `Displays` | `hyprctl monitors -j`; VRR **por conector** (Nunca/Automático/Siempre) → `sylphrena-monitors.lua` + `hyprctl reload` (sin reload VRR off no llega al CRTC) |
| `Hydration` / `Timers` | Complementos on/off; al off limpian estado/procesos y ocultan su UI |
| `Keybinds` | Grabación de teclas con submap vacío de Hyprland (inhibe binds), soporte F13–F35, diálogo de conflicto → `sylphrena-binds.lua`; incluye `focusLast` (última ventana cross-desktop) |
| `Hypr` | Bridge de eventos de Hyprland; conectar directos cuando el `rawEvent` no se re-emite; aplica `follow_mouse` (Nexus) a `sylphrena-input.lua` |

Capas internas de Steam (`services/steam/`, no singletons públicos): `SteamFormat`, `SteamApi`, `SteamLibrary`, `SteamAchievements` (RAM+disco `steam-achievements-cache.json`), `SteamLocal`, `SteamActivity` (snapshot por **stdin**).

### UI
- `modules/nexus/pages/`: `DisplayPage`, `UpdatesPage`(+`UpdatesSettings`), `ComplementsPage`, `ShellPage` (activities + look), `KeybindsPage`, `LanguageAndRegion` (tiempo/ubicación)…
- Barra/popouts en `modules/bar/`; panel Juegos en `modules/dashboard/games/`; lock en `modules/lock/` (columna derecha: `NotifDock` 35% + `CompanionPanel` Sylphrena 65%).
- Trampas QML de este codebase: `PageBase` admite **un solo hijo**; no existe `IconButton.Standard`; `HoverHandler` usa `hovered` (no `containsMouse`); para drop de arrastres no fiarse de `DropArea` con reparent al drag-layer — detectar el target bajo el cursor; `ClipRect` no recorta por `radius` sin máscara; un `Process` con stdin heredado cuelga (usar `DEVNULL`); QML no permite anotaciones de tipo en parámetros con valor por defecto; `Row` no acepta asignar `implicitHeight`.

### Scripts (`scripts/`)
- `apply-activity-style.py` — apply de look completo en un solo proceso (~0,38 s).
- `sylphrena-quiet.py` — aplica tema sin volcar secuencias OSC a los PTYs; recarga Kitty, sync Papirus en qt6ct, GTK/colors.css.
- `sync-light-apps-cli.py` — reescrituras de `cli.json` **deben conservar** el postHook de Kitty.
- `steam-nonsteam.py` — VDF + IDs ocultos + sesiones Millennium + caché de historial.
- `steam-activity.py` — poll de procesos `reaper` (sesiones reales) + delta de `playtime_forever` como respaldo; `snapshot` lee JSON por **stdin** (argv sigue para debug).
- `check-system-updates.py` / `run-system-update.sh` — chequeo (stdin `DEVNULL` + timeout) y update.
- `record.sh` / `record-start.sh` — grabación desacoplada del panel; directorio en `SYLPHRENA_RECORDINGS_DIR`.
- `install-system.sh` — piezas de `/etc` con **un solo** `sudo` (se reejecuta a sí mismo). Cada paso es `scripts/system/NN-nombre.sh` con `step_main`. Hoy: `10-greeter.sh` (`/etc/greetd/sylphrena`, `config.toml`, drop-ins de logind). `greeter/install-greeter.sh` solo llama a este.

## 5. Features del fork (resumen)

1. **Activities** — Principal (no eliminable; las demás heredan su look), Juegos, Trabajo. Look por activity: wallpaper + esquema + modo + transparencia + light apps. Apps ancladas por desktop (reglas regex **RE2** con `(?i)`, sin `silent` para que el foco siga la ventana, reintento ~700 ms). Overview `Super+Tab` con drag & drop de ventanas (pins no arrastran). Atajos `Super+Ctrl+←/→` y toggle "saltar entre actividades".
2. **Pantalla** — modo/escala/VRR por monitor con política Nunca/Automático/Siempre.
3. **Juegos (Steam)** — complemento opt-in: stats en shapes M3, hero con portada, carrusel por `lastPlayed`, logros (rareza + bloqueados, descripción siempre visible), heatmap mensual navegable, juegos no Steam + Millennium + sesiones reales Steam.
4. **Updates** — página Nexus + icono/badge en la barra (solo si hay paquetes) + popout; password popup → update en bg con logs en vivo en Nexus.
5. **Clipboard** — popout estilo Sylphrena (`m3surface` + blur), favoritos, búsqueda, previews de imágenes/rutas, pegar en la ventana enfocada.
6. **Madison VPN** — icono en status, dropdown al hover, OTP integrado, settings (host/puerto/user/pass), heal tras sleep.
7. **Complementos** — VPN, Timers, Hidratación (+ Juegos) con icono por fila y limpieza al desactivar. Hidratación: depósito con waves en el dashboard (el calendario del popout del reloj sigue), meta 3000 ml, presets +20/+83/+250/+500, recordatorio con acciones.
8. **Varios** — timers del reloj persistentes, grabación estable + chip REC, capturas sin notificación, clic en notificación → enfoca/abre la app en su workspace, launcher con edición de `.desktop` (hover inferior para abrirlo, se cierra al salir el puntero), tray/status con pastilla al hover unificada, recoloreado forzado a claro de tray sin contraste (Steam/Cursor), Keep-awake (café) activado por defecto, **layout compacto** (ex game mode: solo barra izquierda, gaps/rounding/border 0, sin tocar animaciones/blur/wobble), lock con Sylphrena (65 % inferior) + notifs con scroll (35 %), i18n ES completo, docs README/FEATURES/CHANGELOG.

## 6. Trampas / aprendizajes

- `cmake --install` **sobrescribe `shell.qml`**: revisar `git status` tras cada install y restaurar. (Con `ENABLE_MODULES=plugin` no pasa; la trampa solo aplica al módulo `shell`.)
- Regex de reglas Hyprland = **RE2** (`(?i)`, `\.`, patrones Lua `%%` no).
- Tras cambiar monitor/VRR: siempre `hyprctl reload`.
- El CLI volcaba secuencias OSC a todos los `/dev/pts`; el fork lo parchea vía `scripts/sylphrena-quiet.py` — no quitar el wrapper.
- `Requests.get` ya lleva transfer timeout de 15 s (plugin C++, `~/.local`) — no quitarlo al tocar `requests.cpp`; sin él un hang deja `pending` > 0 para siempre.
- Caché de logros/schema/global% de Steam: RAM + disco `~/.local/state/sylphrena/steam-achievements-cache.json` (TTL ~1 día, namespace por `steamId`; wipe al cambiar API key / Steam ID; invalidate per-app del focus en reload).
- `hyprctl` reporta un booleano de VRR: la **política** vive en el Lua, no la pises con el estado.

### Aislamiento de Plasma (aprendizajes fase 1)

- `QT_QPA_PLATFORMTHEME` tiene **3 fuentes** (pragma de `shell.qml`, `hyprland.lua`, `environment.d`): las tres a la vez o nada. El env de Hyprland y `environment.d` solo normalizan al relogin; el pragma se aplica al restart, pero ojo: un env **ya definido en la sesión** (stale de un login anterior) no se sobreescribe siempre y `/proc/PID/environ` no refleja vars metidas a runtime (solo el snapshot de exec) — validar el tema efectivo con una app Qt, no leyendo el /proc. `environment.d` aplica a cualquier sesión del usuario: `start-user-session.sh` quita `qt6ct` y el `QML_IMPORT_PATH` de Sylphrena en sesiones que no son Hyprland, y al entrar en Hyprland los vuelve a poner. El greeter apaga el VRR del CRTC antes de soltar DRM.
- `_sync_qt6ct` escribe el esquema con **22 roles** (orden del enum `QPalette::ColorRole` de Qt ≥6.6, `Accent` al final — qt6ct mapea índice→rol literal). Escritura atómica temp+rename: el watcher de qt6ct es dir-scoped con debounce.
- `libcolorreload-gtk-module.so` vive vendorizado en `~/.local/share/gtk-3.0/modules/` (GTK resuelve módulos por nombre ahí); **no existe build GTK4 del módulo** (kde-gtk-config solo compila GTK3).
- D-Bus service duplicates: dbus-broker escanea dirs y **el primero que registra gana** (alfabético dentro del dir) — los overrides de usuario van en `~/.local/share/dbus-1/services/` y ganan a `/usr/share`. Tras crear uno, dbus-broker-launch *nota* el cambio y re-escanea (journal: "Noticed file-system modification, trigger reload").

## 7. Pendiente / roadmap

- [x] **Fase 2 — Plasma desinstalado (2026-10-30)**: `pacman -Rs` de `plasma-meta` + Dolphin/Kate/Konsole/KWalletManager y, en un segundo paso, Ark/KCalc/KDialog/Partition Manager (238 paquetes, ~1381 MiB). Se quedaron explícitos `noto-fonts-emoji` y `ttf-hack` (si no, salían como huérfanos); `bluez`/`bluez-utils` ya lo eran. Fuera: `qt6ct`, portales gtk+hyprland, greetd. `qt5-wayland` se quedó ese día por VLC y se quitó con él. `plasma-integration` y `kde-gtk-config` se fueron; el dual-write de `kdeglobals` también. Config/caché/estado de Plasma, Baloo (~1,5 GiB) y KWallet borrados. El módulo GTK `colorreload` sigue vendorizado en `~/.local`. El mismo `-Rs` se llevó `flatpak` (solo era dependencia de `flatpak-kcm`); las apps seguían en `/var/lib/flatpak` pero el `.desktop` llama a `/usr/bin/flatpak`. Reinstalado el 2026-10-30 como **explícito** (Teams, Blender, Bambu Studio, Prism Launcher). No volver a tratarlo como huérfano.

- [x] **Caché de logros de Steam en disco** (TTL ~1 día, `steam-achievements-cache.json`) detrás del façade `Steam`.
- [x] **Partir `services/Steam.qml`** por capas en `services/steam/*` (Format → Activity(+stdin) → Local → Achievements → Api/Library); façade público estable para Complements + Games.
- [x] `steam-activity.py`: snapshot por **stdin** (argv opcional para debug).
- [ ] Tests pytest ligeros: parser VDF, merge de sesiones Millennium, residual delta/sesión.
- [x] Keep-awake: ya no se fuerza a ON al arrancar; respeta `RuntimeState.inhibitIdle` persistido en `/run/user/.../sylphrena/state.json` (default ON; tras reboot de sesión el runtime se pierde y vuelve el default).
- [ ] Heatmap de Steam vacío: pie explicativo ya existe; considerar rellenar cifras del mes con logros cuando no hay tiempo.
- [ ] A futuro: si upstream monta plugins de verdad, mover Madison VPN y Timers como plugins. (API multi-singleton pública de Steam: **no**; se mantiene un solo façade.)

---

*Última actualización: 2026-10-30 (repo GitHub `iMacnucintosh/sylphrena-shell`; versión propia `v0.1.0`, solo tags `v0.*`; greeter en `/etc/greetd/sylphrena` vía `scripts/install-system.sh`; flake de Nix y workflows de GitHub fuera del árbol; empaquetado AUR pendiente). Mantener este fichero al día con cada feature grande o aprendizaje nuevo.*
