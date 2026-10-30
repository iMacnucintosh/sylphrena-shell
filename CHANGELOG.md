# Changelog

Cambios relevantes de este fork respecto a releases internas. El detalle de uso está en [FEATURES.md](./FEATURES.md).

## 2026-10-30

### Polish (deep audit)

- `steam-activity.py` snapshot: entries with legacy/`[minutes, 0]` timestamps are **rebaselined** (no residual from `since=0`), so heatmap deltas stop being swallowed by tracked sessions after the next Games reload.
- Area picker clipboard-only capture copies via argv (`$1`), not shell string concat.
- Notification popup expiry timer only runs while `popup` is true (history entries idle; re-show re-arms).

### Nexus — reorganización del sidebar (fase 1)

- Categorías visibles en el nav; agrupación tras feedback Jorge: **Escritorio y apariencia** (Activities, Panels, Complements), Entrada, **Dispositivos** (Network, Connected devices, Audio), Apps, Sistema, Acerca de.
- Orden sidebar: Activities → Panels → Complements → Keyboard & mouse → Network → Bluetooth → Audio → Apps → Updates → Language & region → Tuning (`id: services`) → About.
- **Display** (Hz/escala/VRR) es subpágina de **Connected devices** (no aparece sola en el sidebar); sin deep-links top-level a `display`.
- `smartScheme` se edita en Activities; incrementos volumen/brillo/max volume en Audio (paths `services.*` intactos).
- Cross-links Activities ↔ Taskbar Workspaces, Clock → Complements (Timers), Status icons → Complements (Madison), Display → Compact layout en Utilities.
- Docs: «Nexus → Shell» / «Services → Clipboard» alineados a Activities / Complements.

### Juegos (Steam)

- Caché en disco de logros / schema / % global (`~/.local/state/sylphrena/steam-achievements-cache.json`, TTL ~1 día; wipe al cambiar API key o Steam ID; invalidate del juego enfocado en cada reload).
- `services/Steam.qml` pasa a façade público estable; lógica partida en `services/steam/` (`SteamFormat`, `SteamApi`, `SteamLibrary`, `SteamAchievements`, `SteamLocal`, `SteamActivity`).
- `steam-activity.py snapshot` acepta el JSON de playtime por **stdin** (evita `ARG_MAX`); argv sigue válido para debug.

### Atajos

- Nuevo atajo remapeable en Nexus → Keyboard & mouse: **Última ventana** (`focusLast`) → `hl.dsp.focus({ last = true })`. Por defecto **Super + \`**. Alterna entre la ventana actual y la anterior en cualquier escritorio/actividad.
- Nexus → Keyboard & mouse: opción **Foco del ratón** (al pasar / al clic) → `input:follow_mouse` vía `sylphrena-input.lua` (`general.followMouse`).

### Rebrand → Sylphrena (instancia Quickshell `sylphrena`)

- CLI fork `sylph` (`sylphrena-cli`); wrapper de tema `scripts/sylphrena-quiet.py`.
- Runtime/state/cache en `~/.config|state|cache/sylphrena/`. El plugin escribe ya `/sylphrena`.
- Env vars `SYLPHRENA_*`; Lua generados `sylphrena-{binds,activity-rules,monitors}.lua`.
- Globals Hyprland `sylphrena:*` (`CustomShortcut` appid); namespaces de capa `sylphrena-*`.
- OpenCode twins `sylphrena`/`sylphrena-alt`; qt6ct scheme `sylphrena.conf`; Kitty include bajo state `sylphrena`.
- Instancia Quickshell: `~/.config/quickshell/sylphrena` (`sylphrena` → symlink) y arranque Hyprland con `/home/manu/.local/bin/sylph shell -d` (el PATH del compositor no incluye `~/.local/bin`).
- Plugin C++: URI QML `import Sylphrena` (módulos `Sylphrena.*`) y segmento de path `/sylphrena`. Los namespaces C++ `sylphrena::` se quedan.
- Greeter: `/etc/greetd/sylphrena`. `scripts/install-system.sh` pide root una vez y corre los pasos de `scripts/system/`; `greeter/install-greeter.sh` entra por ahí.
- Plasma desde el greeter: se apaga el VRR antes de soltar el CRTC (KWin hacía `Modeset failed: Invalid argument` a 144 Hz) y la sesión no hereda `qt6ct` ni el path QML de Sylphrena. Hyprland los restaura al entrar.
- Plasma desinstalado (`plasma-meta`, apps KDE explícitas y sus huérfanos: 238 paquetes, ~1381 MiB). Se conservan Bluetooth, Noto emoji, Hack, qt6ct y los portales gtk/hyprland. El tema ya no escribe `kdeglobals`.
- VLC desinstalado, y con él `qt5-wayland`, `qt5-declarative`, `qt5-svg` y `qt5-x11extras`. `general.apps.playback` queda vacío.
- OpenSCAD desinstalado. Con él se van `qt5-base`, `qt5-multimedia` y `qscintilla-qt5`: ya no queda Qt 5.
- En esta máquina se desinstalaron los paquetes AUR del proyecto original. La shell se arranca con `sylph`. Quickshell, las fuentes, cliphist y la grabación se quedaron marcados como explícitos, porque el checkout los usa aunque pacman los contaba como dependencia de esos paquetes.
- El flake de Nix y los workflows de GitHub salen del árbol. Pendiente: publicar el paquete AUR con el nombre Sylphrena.
- La versión propia empieza en `v0.1.0`. El build solo lee tags `v0.*`; `v1.*` y `v2.*` siguen siendo del proyecto original.
- El repositorio de GitHub se llama [sylphrena-shell](https://github.com/iMacnucintosh/sylphrena-shell). Las URLs anteriores redirigen.

### Utilities / keep-awake

- Keep-awake (café) ya **no se fuerza a ON** en cada arranque de la shell. Respeta `RuntimeState.inhibitIdle` persistido en `/run/user/$UID/sylphrena/state.json` (default ON). Tras logout/reboot de sesión el runtime se pierde y vuelve el default.

### Compañera Sylphrena (greeter + lock)

- Las tres líneas del Primer Ideal y la de los spren pasan a ser **versos propios** con el mismo ritmo («El aliento antes que el silencio», «La grieta antes que el acero», «Los pasos antes que la meta», «Los espíritus del viento somos pacientes… a veces»): la compañera conserva su voz y su carácter sin reproducir la traducción publicada. Comentarios y documentación usan «espíritu del viento».
- `greeter/modules/CompanionPanel.qml` y `modules/lock/CompanionPanel.qml` actualizados (msgids nuevos en `es.po`, plugin I18n recompilado e instalado en `~/.local`); la copia desplegada del greeter en `/etc/greetd/sylphrena/qs/` queda sincronizada.

## 2026-10-30

### Greeter

- Elegir **Plasma (Wayland)** ya no vuelve al login: se lanza el `Exec` del `.desktop` por argv (sin `sh -c`), se conserva el TTY para KWin y el compositor del greeter suelta el DRM/VT en vez de dejarlo colgado tras un SIGKILL.

## 2026-10-29

### Updates

- Al pulsar **Actualizar** en el popout de la bandeja, el campo de contraseña recibe el foco solo (teclado Exclusive en el diálogo).
- El instalador vuelve a usar `sudo -A`, pero la contraseña vive en un helper en RAM (socket unix en `$XDG_RUNTIME_DIR`, sin fichero). El timestamp de `sudo -S -v` no sirve aquí: es por TTY y el Process de Quickshell no tiene TTY, así que `-n` fallaba con «a password is required».

### Lockscreen

- La columna derecha se parte **35/65**: **notificaciones arriba** (con scrollbar) y **Sylphrena abajo**, la misma compañera del greeter (máquina de escribir, orbe SoftBurst, estados PAM de escuchando / error / desbloqueo).

### Aislamiento de Plasma (fase 1)

- **Login**: plasmalogin → greetd con autologin inicial a Hyprland y greeter Quickshell Material You tras logout. Teclado español fijo; handoff corto bajo cortina negra, VT limpio y recuperación ante timeout. Tanto el greeter como la sesión de usuario arrancan Hyprland sin TTY de control y con stdout a log (el logo ASCII + debug ya no quedan en el búfer de tty1); `UserStopDelaySec=0` y `TimeoutStopSec=8` en user@ evitan la pantalla negra de ~10 s al reentrar (systemd no espera al user@ anterior ni a coredumps enormes); el compositor desechable se termina por su watchdog para evitar el shutdown de Hyprland 0.57 que tardaba ~5 s y acababa en segfault; plasmalogin sigue instalado pero deshabilitado.
- **Qt sin plasma-integration**: `QT_QPA_PLATFORMTHEME=kde → qt6ct` en `shell.qml`, `hyprland.lua` y `environment.d`. Los apps Qt pasan de Breeze a Fusion con la **paleta Material**: `sylphrena-quiet.py` genera en cada cambio de esquema `~/.config/qt6ct/colors/sylphrena.conf` (22 roles de QPalette desde los tokens Material) + `qt6ct.conf` (Papirus por modo, Fusion), con escritura atómica para el hot-reload de qt6ct.
- **Thunar sin Dolphin**: `plasma-dolphin`/`plasma-kactivitymanagerd` parados y enmascarados (user systemd); override D-Bus de `org.freedesktop.FileManager1` a Thunar (`~/.local/share/dbus-1/services/`). "Open containing folder" y similares ya no suben Dolphin.
- **`colorreload-gtk-module` vendorizado** en `~/.local/share/gtk-3.0/modules/` (copia del .so de kde-gtk-config): la recarga en vivo de Thunar sobrevive a la desinstalación de Plasma.
- **Cursor unificado**: `breeze_cursors → Adwaita` (`gsettings`, `settings.ini`, `XCURSOR_THEME`/`HYPRCURSOR_THEME` en `hyprland.lua`).
- Todo lo demás (iconos de apps, GTK live-reload, portales) sigue igual — queda un dual-write de `kdeglobals [Icons]` mientras `plasma-integration` siga instalada (se retira en fase 2).

### Sync upstream

- Merge de `upstream/main` (PR #1: `feat(lock): clear password with Ctrl+U`). El fork lleva remote `upstream` al proyecto original; las actualizaciones de base se hacen mergeando upstream y pasando PR a `main`.
- `.cursor-tmp/` añadido a `.gitignore`.

### Repaso integral de calidad (fixes)

- **Clipboard**: el contenido del portapapeles ya no se interpola en cadenas `sh -c` (va por argv `"$1"`, era inyección); verificación en lote de que el fichero de una imagen existe (texto que acaba en `.jpg` ya no aparece como imagen rota); miniaturas decodificadas al tamaño del thumb (`sourceSize`); favoritos binarios emparejados por id de cliphist.
- **Madison VPN**: el status en cola ya no resetea `busy` en mitad de un connect/disconnect (antes re-habilitaba el botón y un segundo intento mataba el túnel); el script local `disconnect_vpn.sh` ya no duplica la notificación.
- **Activities**: verificación de inicial del look capada a 3 reintentos (un esquema corrupto ya no relanza el apply python sin fin) y `lastAppliedStyleKey` solo se confirma con exit 0.
- **Requests (plugin C++)**: `get` con transfer timeout de 15 s; el plugin se compila a `~/.local` y `shell.qml` lo carga con `QT_ADDITIONAL_PACKAGES_PREFIX_PATH` (sin sudo).
- **Updates**: la contraseña del sudo vive solo en RAM (`sudo -S -v` por paso en `run-system-update.sh`, sin fichero de askpass); el timeout de instalación solo corta si lleva 45 min sin imprimir nada (heartbeat por línea de log).
- **Pantalla**: refresh automático en `monitoradded`/`monitorremoved` y `persist()` conserva las políticas VRR de outputs desenchufados.
- **Juegos (Steam)**: muestreo de logros capado a 60 juegos (los más jugados) y refresco periódico solo con la pestaña Juegos visible.
- **OpenCode**: tema `sylphrena` con gemelas `sylphrena`/`sylphrena-alt` para el hot-reload por flip de nombre; `generate-opencode-theme.py` calcula `pick_sources()` una sola vez.

### Nexus reorganizado

- Apariencia **unificada en Activities**: la tarjeta de Principal es el "look general" (las demás heredan o overridean), marqué con etiqueta "Look general"; el switch maestro de fondo de pantalla va en General. Sin doble sitio para el estético.
- **Complementos** es el hub de todos los features opt-in: Madison VPN, Timers, Hidratación, Juegos/Steam y **Clipboard** (su max-items migró desde Services, que queda para servicios de sistema).
- Páginas con `id` estable + `PageRegistry.idxOf()`: el salto Updates→Nexus ya no se descoloca al insertar páginas.
- Status icons: updates y VPN usan auto-hide con config real (`bar.status.onlyShowUpdatesWithUpdates` + complemento), con toggles/fila en `Panels → Taskbar → Status icons → Auto-hide`; la batería quedó **vanilla** (se muestra/oculta con la lista "Visible icons"). Contenido de workspaces movido a Activities ("Escritorios de la barra"), que guarda solo apariencia en Taskbar.

### Coherencia con vanilla (poda de fork)

- **Batería revertida a vanilla**: el popout es byte-exacto al de upstream (sin gates por `isLaptopBattery`, selector de perfiles siempre); se elimina `bar.status.hideBatteryOnDesktops` y su toggle; el icono se oculta por la lista de statusIcons.
- **Reloj revertido al interior vanilla**: la pastilla de hover de bar permanece (el popout del reloj es del fork), pero el fondo en reposo respeta el toggle "Fondo", el padding es condicional y el centrado del calendario vuelve al layout vanilla.
- **Timers en la página del Reloj**: fila desplegable en `Panels → Taskbar → Clock` (mismo patrón que Hidratación) con subtexto «Temporizadores rápidos» y edición de los 4 presets (`addons.timers.presetMins0..3`); el popout del reloj los consume. Mismo `addons.timers.enabled` que Complementos.

### Nexus → Pantalla (Display)

- Nueva UI de pantallas (hoy subpágina de Connected devices): una tarjeta por monitor con **modo (Hz)**, **escala** y **VRR / Adaptive Sync**.
- Política VRR estilo Plasma: **Nunca / Automático / Siempre** (Automático = solo a pantalla completa).
- Persistencia por conector en `~/.config/hypr/sylphrena-monitors.lua` + `hyprctl reload` al aplicar; la política guardada ya no la pisa el booleano de `hyprctl` (fix del parpadeo con Adaptive Sync pegado en el CRTC). Requiere `require("sylphrena-monitors")` en `hyprland.lua`.

### Layout compacto (ex game mode)

- Redefinido como layout que aprovecha la pantalla al máximo: sin marco de Sylphrena (solo barra izquierda, `reserved: 60 0 0 0`), gaps 0, `rounding`/`border_size` 0 y sin hueco entre barra y ventanas (smoothing 0 + solape 1px).
- Ya **no** toca animaciones, blur, sombras, wobble ni tearing. El id interno sigue siendo `gameMode` (IPC / quick toggle `fit_screen`).

## 2026-10-28

### Juegos (Steam)

- Pestaña **Juegos** en el dashboard (complemento opt-in): perfil, stats Material You, hero, selector por última partida.
- Lista única de logros (scroll): desbloqueados por rareza, luego bloqueados; descripciones siempre visibles.
- Mapa de calor mensual con navegación entre meses; puntos en días con logros.
- Juegos no Steam (`shortcuts.vdf` + arte local); filtra la colección Hidden de Steam.
- Horas no Steam vía plugin Millennium; sesiones Steam vía `reaper` + delta de playtime.
- Refresco automático configurable en Nexus (default 10 min); la API key va oculta, con botón de mostrar.
- Al refrescar se conserva el juego seleccionado.

### Notificaciones / hidratación / tiempo

- Hover en las esquinas derecha abre la sidebar de notificaciones.
- Hidratación: persistencia del último recordatorio para no repetirlo al reiniciar la shell.
- Amanecer/atardecer en 24 h usan `HH:mm` (antes se mostraban en ciclo 1–12).

### Higiene

- `.gitignore` cubre `__pycache__/` de los scripts Python.

## 2026-10-27

### System updates

- Página **Nexus → Updates** (lista desplegable, refrescar, actualizar sistema / paquete).
- Fuentes configurables (Arch, AUR, Flatpak; todas on por defecto); wrapper AUR default **yay**.
- Icono en la pastilla de status (junto a VPN) solo si hay updates; popout rápido + enlace a Nexus.
- Poll cada 30 min; toast de paquetes nuevos (configurable, default on).
- Actualizar sistema: password popup → fondo desde el panel / logs en Nexus; toast al terminar.

### Clipboard

- Historial flotante estilo Plasma/Sylphrena (`cliphist`): **Super+Shift+V** (remapeable).
- Pegado directo en la ventana enfocada (`wtype` Ctrl+V).
- Favoritos persistentes, búsqueda, miniaturas de imagen.
- Rutas/`file://` a imagen desde el explorador se muestran y pegan como imagen.
- Misma superficie/blur que el panel izquierdo; límite configurable (default 50) en Nexus → Complements.

### Complementos / Madison VPN / Timers

- **Nexus → Complementos**: toggles Madison VPN + Timers (iconos `verified_user` / `timer`).
- VPN off: oculta icono, para poll, teardown disconnect+heal.
- Timers off: limpia timers activos y oculta la sección en el popout del reloj.
- Icono VPN en la pastilla de status (bajo Bluetooth) cuando el complemento está on.
- Clic = conectar (diálogo OTP Sylphrena) / desconectar.
- Engranaje en el popout: editar config local de openfortivpn (sin secretos en el repo).
- Scripts en `madison_vpn_widget` (`hyprland/`) instalados a `~/.local/share/madison-vpn/`.
- Tras **suspender/reanudar**: health-check (ping a intranet); si el túnel está zombie se limpia y el icono pasa a desconectado (toast). Comando `madison-vpn heal` + `heal_vpn.sh`.

### Activities / tema

- Apply de look **atómico y fiable**: `scripts/apply-activity-style.py` (wallpaper + un solo `scheme set`, sin carrera light/dark).
- Modo/variant de la activity tienen prioridad sobre `smartScheme` (luminancia del wallpaper).
- Verify + reintento si el modo no cuadra tras el apply.
- **GTK/Thunar** siguen el esquema dinámico de la activity (`enableGtk` siempre on; `colors.css` para `colorreload`).
- **Apps claras** de la activity: `prefer-light` + sin motor Qt oscuro; Thunar puede seguir el CSS del esquema.
- Iconos del launcher vía tema KDE: sync **Papirus** en `kdeglobals` desde `sylphrena-quiet.py` (ya no depende solo de Breeze).

### Grabación de pantalla

- Carpeta por defecto: `~/Vídeos/Videocapturas de pantalla` (`SYLPHRENA_RECORDINGS_DIR` / `Paths.recsdir`).
- Wrappers `record-start.sh` / `record.sh` fijan esa ruta al start/stop/pause.
- Abrir carpeta desde la lista usa el explorador configurado (`thunar` por defecto).
- Reproducir (▶) abre con `apps.playback` (**VLC** por defecto); MIME `video/*` también apunta a VLC.

### Explorador / Hyprland

- **Thunar** como file manager por defecto (`xdg-mime` + Super+E vía `apps.explorer`).
- Dependencias recomendadas para theming: `adw-gtk-theme`, `papirus-icon-theme`, `hyprpolkitagent` (diálogos pkexec).

### Utilities

- **Mantener activo** pasa a interruptor rápido (icono café, a la izquierda del gamepad); la card grande queda desactivada por defecto.
- Idle inhibit **activado por defecto** (`RuntimeState.inhibitIdle`) para no suspender por inactividad.

### Capturas

- Captura a portapapeles (picker) **sin notificación**.

## 2026-10-26

### Launcher

- Menú contextual al clic derecho sobre apps (editar `.desktop`, favoritos, ocultar, restablecer).
- Diálogo de edición centrado (`DesktopEditDialog`) con selector de icono; el launcher no se cierra al editar.
- Un solo menú contextual abierto a la vez (`Menus.qml`); el clic en ítems funciona sobre el texto.
- Overrides de `.desktop` resueltos y guardados de forma fiable en `~/.local/share/applications`.

### Grabación de pantalla

- Arranque desacoplado del panel (`scripts/record-start.sh` + `execDetached`) para que no se cancele al salir el ratón o cambiar de workspace.
- Utilities/sidebar se mantienen abiertos mientras `Recorder.running` / `arming`.
- Indicador **REC** / **PAUSE** bajo el reloj en la barra.
- El botón principal no re-dispara start durante una captura activa.

### Activities / tema

- Overview: arrastrar ventanas entre desktops/activities y enfocar el destino al soltar.
- Estilo por activity al cambiar de foco (wallpaper, esquema, modo, transparency, light apps).
- Integración Kitty: plantilla de usuario, `include` del tema generado, recarga en vivo al cambiar activity.
- `sylphrena-quiet.py` recarga Kitty tras aplicar colores; `sync-light-apps-cli.py` conserva el hook de recarga (ya no lo pisa).

### Barra / UI

- Centrado estable del reloj.
- Traducciones ES ampliadas para las cadenas nuevas.
