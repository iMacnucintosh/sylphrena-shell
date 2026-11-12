# Guía de uso (Sylphrena)

Detalle de cómo usar las piezas del fork. Listado corto y cara pública: **[README.md](./README.md)**.  
Opciones `shell.json`: **[CONFIG.md](./CONFIG.md)**. Changelog: **[CHANGELOG.md](./CHANGELOG.md)**.

Repositorio: [iMacnucintosh/sylphrena-shell](https://github.com/iMacnucintosh/sylphrena-shell). Crédito a la base caelestia en el README.

---

## Activities (espacios agrupados)

Sistema opcional (activado por defecto en este fork) que agrupa desktops de Hyprland en **actividades**.

### En la barra

- En lugar del strip clásico de workspaces, ves una **pill por actividad** (icono + sus desktops).
- Clic en el icono de la actividad → salta a su primer desktop.
- Clic derecho en el icono → popout integrado junto a la barra (p. ej. cerrar todas las ventanas de esa activity).
- El scroll de workspaces se queda **dentro** de la actividad actual (no salta a otra actividad).

### Overview

- Atajo por defecto: **Super + Tab** (remapeable); también funciona con una app a pantalla completa (p. ej. un juego).
- Vista a pantalla completa de todas las actividades y sus desktops.
- Clic en un desktop para ir a él.
- Arrastra ventanas entre desktops (también entre activities); al soltar se enfoca el destino y se aplica su look.
- Apps **ancladas (pinned)** no se arrastran y muestran un icono de pin.
- Si una ventana tiene audio (PipeWire), un chip pequeño de volumen abajo a la izquierda permite silenciarla / reactivarla sin salir del overview.
- Cierra con Escape o clic fuera.

### Cambiar de actividad

- Por defecto: **Super + Ctrl + ← / →** (al primer desktop de la activity anterior/siguiente).
- Remapeable en **Nexus → Keyboard & mouse**.

### Estilo por actividad

Al cambiar de actividad puedes aplicar (y recordar) de forma independiente:

- Wallpaper
- Esquema / colores
- Modo claro / oscuro
- Transparencia
- “Light apps” (apps Adwaita/Qt en claro aunque el shell esté oscuro)

Las actividades que no son la principal pueden **heredar** el look de Home o definir el suyo.

El apply es **un solo proceso** (`scripts/apply-activity-style.py`): evita carreras light/dark y respeta el modo de la activity aunque `smartScheme` esté activo. GTK/Thunar se actualizan con la paleta Material (recarga en vivo vía `colors.css` + `colorreload-gtk-module`).

### Apps ancladas a un desktop

Desde **Nexus → Activities** puedes asociar aplicaciones a un desktop concreto de una activity.  
Hyprland aplica esas reglas al arrancar (archivo generado `~/.config/hypr/sylphrena-activity-rules.lua`).

### Configuración

**Nexus → Activities**:

- Siempre activas (puede haber solo Principal o varias; sin interruptor Activar/desactivar)
- Mostrar iconos de apps en los workspaces de la barra
- Crear, renombrar, elegir icono y número de desktops (1–10)
- Look por activity
- Pin de apps por desktop

Defaults de ejemplo: Principal (2 desktops), Juegos (1), Trabajo (2).
Principal no se puede eliminar.

### Setup Hyprland (importante)

En tu config Lua de Hyprland:

```lua
require("sylphrena-binds")           -- atajos (Nexus → Keyboard & mouse)
require("sylphrena-activity-rules")  -- reglas de activities / pins (Nexus → Activities)
```

---

## Launcher (menú de aplicaciones)

- Atajo (en tu setup): **Alt + Space** (remapeable en Nexus → Keyboard & mouse).
- También se abre al llevar el puntero al **borde inferior**, en la zona centrada del launcher (como un panel).
- Se cierra al sacar el puntero (como el dashboard), con Escape, al elegir una app, o al perder el foco.
  Si lo abriste con el atajo, se mantiene hasta Escape / elegir app (igual que el resto de paneles por tecla).
- Se puede desactivar el hover en **Nexus → Panels → Launcher → Show on hover**.
- La búsqueda normal compara el **nombre**; después de esos resultados se añaden las apps cuyo `Keywords` del `.desktop` tenga una palabra que empiece por lo escrito (mín. 3 letras). Así «seeker» encuentra *Archivos* y «things» encuentra *Paquetes*.
- **Clic derecho** sobre una app: menú contextual (un solo menú abierto a la vez) con:
  - Editar nombre / descripción / icono (diálogo centrado; el launcher no se cierra al editar)
  - Override guardado en `~/.local/share/applications`
  - Favoritos, ocultar o restablecer la personalización

---

## Grabación de pantalla

- Card de **Screen recorder** en el panel de utilities (fullscreen / región, con o sin audio).
- El arranque va **desacoplado** del ciclo de vida del panel (`scripts/record-start.sh` / `record.sh`), así la captura **no se aborta** al sacar el ratón del panel o al cambiar de desktop.
- Mientras grabas, utilities/sidebar **permanecen abiertos** al salir el puntero (evita teardowns mid-capture).
- Indicador **REC** / **PAUSE** bajo el reloj en la barra mientras hay grabación activa.
- El chip principal del recorder no re-dispara start mientras ya está grabando (evita toggle-stop accidental).
- Archivos en **`~/Vídeos/Videocapturas de pantalla`** (override: env `SYLPHRENA_RECORDINGS_DIR`).
- Desde la lista: reproducir, abrir carpeta (Seeker) o borrar.

---

## System updates

Inspirado en [arch-update-checker](https://github.com/iMacnucintosh/arch-update-checker):

- **Nexus → Updates**: refrescar, contador, actualizar sistema, lista expandable (info / update / uninstall / URL).
- Engranaje → fuentes (Arch / AUR / Flatpak, todas on por defecto), wrapper AUR (**yay**), intervalo, notificaciones, single-package.
- Icono en status (junto a la VPN FortiClient) **solo si hay paquetes**; badge con el número; popout rápido.
- Poll cada **30 min**; toast al detectar paquetes nuevos (default on).
- **Actualizar sistema**: popup de contraseña → en **panel** corre en segundo plano; en **Nexus** muestra log en vivo. Notificación al terminar + rechequeo. Paquete suelto / orphans siguen en terminal.
- **Seguridad del install**: la contraseña vive **solo en memoria** (helper Python + socket unix en `$XDG_RUNTIME_DIR`; no hay fichero `.pw`). yay/pacman usan **`sudo -A`** contra ese askpass — el timestamp de sudo es por TTY y no sobrevive a un Process sin TTY. El timeout de instalación (45 min) tiene *heartbeat*: solo corta si el instalador lleva 45 min **sin imprimir nada** — nunca mata un `pacman` en mitad de una transacción.

---

## Extensiones (v0.2)

Las funciones opcionales viven en `extensions/` y se activan en Nexus: **widgets** del carrusel (Tareas, Hidratación) en `Panels → Dashboard → Carrusel de widgets` y **extensiones** (VPN FortiClient, Juegos) en `Extensiones`. Nada está activado por defecto y desactivar una extensión no borra sus datos. Para escribir una, ver `AGENTS.md` (sección «Extensiones») y el ejemplo `docs/examples/extension-spike/`; las de usuario se instalan con Things (sección Sylphrena) o con `scripts/ext.py` en `~/.local/share/sylphrena/extensions/<id>/`.

## Extensiones

Página **Nexus → Extensiones** (sustituye el placeholder de Plugins):

- Lista de features opcionales del fork, con icono identificativo por fila.
- **VPN FortiClient** (extensión aparte, se instala con Things: ver «Extensiones»); después, interruptor on/off. Al activarla aparece el tipo **FortiClient** en Nexus → Red → Añadir proveedor.
- **Timers** (base): ya no está en Extensiones; su interruptor on/off y sus presets viven en **Nexus → Panels → Taskbar → Clock** (`addons.timers.enabled`). Al desactivar se limpian timers activos y se oculta la sección del popout del reloj (el calendario sigue).
- **Hidratación** (extensión `hydration`, del hub: se instala con Things): se activa en `Panels → Dashboard → Carrusel de widgets` (`extensions.enabled`); apagarla descarga el servicio (recordatorios y seguimiento) pero conserva los datos. Depósito con waves (shader propio `water.frag.qsb`), meta diaria (default 3000 ml), botones +20/+83/+250/+500 configurables, undo del último trago, y recordatorio con acciones si pasan N minutos (default 15) sin registrar un trago. Sus ajustes viven en `~/.config/sylphrena/extensions/hydration.json` (se migran solos desde `addons.hydration`). Estado en `~/.local/state/sylphrena/hydration.json`.
- **Juegos (Steam)** (extensión `games`, del hub: se instala con Things; ajustes en `~/.config/sylphrena/extensions/games.json`): interruptor on/off (opt-in). Al activar añade la pestaña **Juegos** en el dashboard (a la derecha de Tiempo). Configura API key (oculta por defecto) + Steam ID / vanity / URL de perfil, y el intervalo de refresco (default 10 min). Muestra perfil y nivel, estadísticas globales en shapes Material You (juegos visibles — sin la colección Hidden —, horas, compleción media de logros y juegos al 100 %, amigos en línea), tarjeta del juego destacado con portada y progreso, y un selector de portadas ordenado por última partida. Logros en una lista con scroll: desbloqueados por rareza y bloqueados de más común a más raro, con insignia y descripción. Mapa de calor mensual (puntos = días con logros; el tiempo por día se registra con el shell en marcha). Juegos no Steam desde `shortcuts.vdf`, con horas de Millennium si está instalado. Los logros del perfil deben ser públicos. El muestreo de logros para la compleción media está **capado a 60 juegos** (los más jugados, por orden de playtime) y el refresco periódico **solo corre mientras el dashboard muestra la pestaña Juegos** (no quema API en segundo plano). Caché de logros/schema/% global en disco (`~/.local/state/sylphrena/steam-achievements-cache.json`, TTL ~1 día) para arranques en frío más rápidos; el servicio QML es un façade (`Steam`) con capas en `services/steam/*`.

## Extensiones: instalar con Things

**Nexus → Extensiones** lista las extensiones instaladas: cada una con su icono, nombre y descripción, un interruptor para activarla y, si tiene ajustes, un desplegable. Si una no puede correr, la tarjeta dice por qué (por ejemplo, «Necesita Sylphrena >=0.3.0») o avisa de que le faltan sus piezas de sistema. La fila de arriba, **Buscar más en Things**, abre Things (desactivada, con aviso, si no está instalado).

**Instalar, actualizar y quitar se hace en Things**, en su sección **Sylphrena** (`Ctrl+4`), que lee el catálogo del [Sylphrena Hub](https://github.com/iMacnucintosh/sylphrena-hub): extensiones disponibles, instaladas, actualizables y locales. Pide la contraseña solo si la extensión instala algo como administrador, comprueba la huella (`sha256`) y la compatibilidad antes de instalar, y activa la extensión al terminar (o recarga la shell si era una actualización de una ya cargada). Quitar una extensión borra también sus conexiones (por ejemplo las VPN de su tipo); desactivarla desde Nexus las conserva.

Sin Things, lo mismo desde una terminal con `scripts/ext.py` (`list`, `install <zip>`, `install-hub`, `remove`, `enable`, `disable`, `rescan`). Una extensión instalada a mano en `~/.local/share/sylphrena/extensions/` se muestra en Things como «local» y no se toca.

Una extensión de fuera trae sus **traducciones** en `i18n/<idioma>.json` (msgid, o `contexto\u0004msgid`, → traducción); `Tr` las usa cuando la shell no tiene la cadena. Para generarlas desde un `.po`: `scripts/extension-catalog.py <carpeta de la extensión> plugin/src/Sylphrena/I18n/trs/es.po`.

### VPN FortiClient

La extensión `vpn-forticlient` (tipo de proveedor FortiClient para la VPN de Nexus → Red: OTP opcional, certificados, host de comprobación, DNS, entradas de hosts; contraseña solo en `~/.config/sylphrena/vpn/<id>.conf`) ya no viene con la shell: vive en su propio repo, junto a su zip y su documentación. Se instala con Things (pide la contraseña: ayudante root `sylphrena-fortivpn` + regla de sudoers). Sus conexiones en `shell.json` (`type: "ext:vpn-forticlient"`) se conservan aunque no esté instalada: aparecen como «extensión desactivada».

---

## Configuración inicial

Una instalación nueva no arranca con los valores de fábrica sino con los ajustes con los que se usa Sylphrena (barra, dashboard,
launcher, notificaciones, utilidades, apps por defecto: Seeker y kitty), **una sola actividad (Principal) con dos escritorios** y
su fondo de pantalla, que viene con la shell (`assets/wallpapers/`). Lo escribe `scripts/setup-defaults.py`
(`services/DefaultsSetup.qml`) **solo si no existe `~/.config/sylphrena/shell.json`** (o está vacío): nunca toca una
configuración que ya tengas, y no vuelve a ejecutarse (`~/.local/state/sylphrena/defaults.json`). La plantilla es
`assets/defaults/shell.json`: no lleva nada personal (apps favoritas, ubicación del tiempo, conexiones VPN, extensiones activas…).
`python3 scripts/setup-defaults.py --check` dice si haría algo. Los atajos por defecto son los del catálogo, no los tuyos.

## Asistente de bienvenida

Una ventana propia, **flotante y de tamaño fijo** (960×720, centrada: Hyprland flota las ventanas de tamaño fijo, sin reglas), con cinco pasos que sale **sola la primera vez** que arranca la shell (a los 4 s) y se puede volver a abrir con el **botón de varita** de la tarjeta de Sylphrena en **Nexus → Acerca de** (abajo a la derecha; tooltip «Guía de bienvenida»):

1. **Qué es Sylphrena:** el orbe, una frase, quién la hace (**iMacnucintosh**, con enlace a GitHub) y el crédito al proyecto original (**caelestia-shell**, de soramane).
2. **Qué te ofrece:** tarjetas con Actividades, Nexus, el panel, Material You, Extensiones y bloqueo/inicio de sesión.
3. **Aplicaciones hechas para Sylphrena:** presenta **Seeker** (explorador de archivos), **Things** (gestor de paquetes) y **kitty** (la terminal, que la shell recolorea en vivo). Es **informativo**: no instala nada (las instala el paquete base); si una está instalada ofrece abrirla, y si no, indica «No instalada». Debajo, una nota aclara que **kitty viene preinstalada pero se puede usar cualquier otra terminal**, con un botón «Elegir terminal» que abre Nexus → Aplicaciones.
4. **Tus atajos:** tabla de los atajos en uso ahora, por categorías y con las teclas dibujadas (los numerados se agrupan: «Ir al escritorio 1–10»). Sigue a Nexus: si cambias uno allí, cambia aquí. Botón **Editar en Nexus** (Nexus → Teclado y ratón, donde también se exportan e importan).
5. **Todo listo:** abre Nexus o termina. Incluye una invitación a **crear tus propias extensiones** (una carpeta con un manifiesto y unos pocos ficheros QML) y a compartirlas en el Sylphrena Hub, con enlace a su repo. El paso 2 también lo menciona en la tarjeta de Extensiones.

Cerrarla, omitirla o terminarla cuenta como vista (`~/.local/state/sylphrena/welcome.json`); para que vuelva a salir sola: `qs -c sylphrena ipc call welcome reset`. Las capturas reales de la shell se añadirán más adelante (por ahora el orbe y tarjetas Material You).

En **Nexus → Extensiones**, la fila **Buscar más en Things** abre Things (botón desactivado, con aviso, si no está instalado).

## Pantalla (modos, escala, VRR)

Bloque **Pantalla** inline en **Nexus → Dispositivos conectados** (categoría Dispositivos; sin entrada propia en el sidebar), una tarjeta por monitor:

- **Resolución** y **Frecuencia** por separado (la lista de Hz solo muestra modos de la resolución actual).
- **Escala**.
- **VRR / Adaptive Sync** con política estilo Plasma: **Nunca / Automático / Siempre** (Automático = solo mientras haya algo a pantalla completa).

Persistencia por conector en `~/.config/hypr/sylphrena-monitors.lua`; al aplicar se ejecuta `hyprctl reload`, que es lo que hace que el apagado de VRR llegue de verdad al CRTC. La política vive en el Lua y el estado "activo" que reporta `hyprctl` no pisa tu elección. Requiere en tu config de Hyprland:

```lua
require("sylphrena-monitors")
```

---

## Utilities / mantener activo

- En **interruptores rápidos**: icono de café (**Keep awake**), a la izquierda del gamepad.
- **Activado por defecto** (bloquea idle/suspend del compositor vía idle inhibitor).
- El estado del interruptor **persiste** entre reinicios de la shell (`sylph shell -r`) vía `RuntimeState` (`/run/user/$UID/sylphrena/state.json`). Tras un logout/reboot de sesión el runtime se pierde y vuelve el default ON.
- La card grande «Mantener activo» está oculta por defecto (se puede volver a mostrar en Nexus → Panels → Utilities → Cards).

---

## Explorador y theming GTK

- Explorador por defecto: **Seeker** (`general.apps.explorer: ["seeker"]` + Super+E + `xdg-mime` para carpetas). Repo aparte `~/Desarrollo/seeker`; tema M3 vía `~/.config/seeker/theme.json` (escrito por `sylphrena-quiet.py`). Thunar sigue disponible como alternativa. Los pickers internos (wallpaper, avatar, icono de `.desktop`) usan `components/filedialog/FileDialog.qml` → `seeker --pick` (sin explorador QML embebido).
- Gestor de paquetes: **Things** (lanzador «Paquetes», repo aparte `~/Desarrollo/things`, pacman + AUR + Flatpak). Tema M3 vía `~/.config/things/theme.json`, escrito por `_sync_things` en `sylphrena-quiet.py` (mismo formato que Seeker; hot-reload).
- Para que Thunar/GTK sigan el esquema de Sylphrena: `adw-gtk-theme`, `papirus-icon-theme`, y `GTK_MODULES=colorreload-gtk-module` (Hyprland + `settings.ini`; el módulo está **vendorizado** en `~/.local/share/gtk-3.0/modules/`, ver abajo).
- Iconos de apps en el launcher: tema **Papirus** (sincronizado en `~/.config/qt6ct/qt6ct.conf [Appearance] icon_theme` al aplicar el esquema).
- Diálogos `pkexec` (Timeshift, VPN helper, etc.): activa `hyprpolkitagent.service` (`systemctl --user enable --now hyprpolkitagent`).

---

## Aislamiento de Plasma (fase 2 hecha)

Plasma ya no está instalado. Hyprland sigue con qt6ct, Papirus, Thunar y los portales gtk + hyprland.

- **Login**: **greetd + greeter Quickshell Material You** con teclado español y autologin inicial a `/usr/bin/start-hyprland`. Tras cerrar sesión, el greeter corre sobre un Hyprland mínimo y entrega la sesión con fundido negro corto: tanto el greeter como la sesión arrancan sin TTY de control (el logo ASCII de Hyprland no llega a tty1), la salida va a `session-startup.log` / `hyprland-greeter.log`, y el compositor desechable se desmonta de inmediato (Hyprland 0.57 se quedaba ~5 s y acababa en segfault al salir). systemd no retiene `user@` 10 s ni espera 90 s a coredumps (`UserStopDelaySec=0`, `TimeoutStopSec=8`). Si greetd no confirma el arranque, recupera la UI en vez de dejar una pantalla negra. Se instala/actualiza con `scripts/install-system.sh` (un solo prompt de root; `greeter/install-greeter.sh` hace lo mismo). `plasma-login-manager` se desinstaló con Plasma.
- **Plataforma Qt**: cambio en 3 sitios de `QT_QPA_PLATFORMTHEME=kde` a `qt6ct`
  (pragma `Env` en `shell.qml`, env en `hyprland.lua`, `~/.config/environment.d/99-qt-platformtheme.conf`)
  — aplica a processes nuevos; la sesión completa se normaliza al relogin. Los apps Qt ya no dependen de
  `plasma-integration` (estilo Breeze → Fusion). `scripts/sylphrena-quiet.py` empuja en cada cambio de esquema (`_sync_qt6ct`), de forma atómica (temp+rename, lo pilla el QFileSystemWatcher de qt6ct):
  - `~/.config/qt6ct/colors/sylphrena.conf`: paleta Qt (22 roles de `QPalette`) mapeada desde los tokens Material de la activity
  - `~/.config/qt6ct/qt6ct.conf`: `icon_theme=Papirus-{Mode}`, `custom_palette=true`, `style=Fusion`
- **Cursor**: alineado GTK/Qt/Hyprland a **Adwaita** (`gsettings cursor-theme`, `gtk-cursor-theme-name` de `settings.ini`, env `XCURSOR_THEME`/`HYPRCURSOR_THEME`).
- **módulo `colorreload-gtk-module`** vendorizado: copia a `~/.local/share/gtk-3.0/modules/`. Sobrevive la desinstalación de `kde-gtk-config` en fase 2 (GTK resuelve el módulo por nombre en la ruta `$XDG_DATA_HOME`). Es un build solo de GTK3 (no existe módulo GTK4).
- **`org.freedesktop.FileManager1`**: Seeker lo sirve. Override a nivel usuario en
  `~/.local/share/dbus-1/services/org.freedesktop.FileManager1.service` (→ `~/.local/bin/seeker`; dbus-broker ignora los duplicados `/usr/share/dbus-1/services/org.kde.dolphin.*`).
- **Unidades de Dolphin y KActivity**: se fueron con los paquetes. Las máscaras de usuario se quitaron.
- **Fase 2 hecha (2026-10-30)**: 238 paquetes KDE/Plasma (~1381 MiB), incluido `plasma-integration` y `kde-gtk-config`. El tema ya no escribe `kdeglobals`. Config, caché y el índice de Baloo se borraron. Siguen `bluez`, `noto-fonts-emoji`, `ttf-hack` y el `colorreload` vendorizado.

---

## Kitty y colores de la activity

Kitty no es un target nativo de Sylphrena; este fork lo integra así. **Desde la 0.3 lo conecta la propia shell** (`services/KittySetup.qml` → `scripts/setup-kitty.py`): en el primer arranque con kitty instalado copia la plantilla (solo si no tienes una) y añade a tu `kitty.conf` un bloque marcado con lo de abajo, solo con lo que falte, dejando una copia `kitty.conf.sylphrena-backup` y avisando con un toast. Respeta un `allow_remote_control no` o un `listen_on` tuyos (no los pisa). Para desconectarlo, borra el bloque (no vuelve a tocarlo: `~/.local/state/sylphrena/kitty-setup.json`). A mano, `python3 scripts/setup-kitty.py --check | --force`. Lo que hace, en detalle:

1. Plantilla de usuario: `~/.config/sylphrena/templates/kitty.conf` (variables `{{ surface.hex }}`, `{{ term0.hex }}`, …).
2. Generada en: `~/.local/state/sylphrena/theme/kitty.conf`.
3. En `~/.config/kitty/kitty.conf`:

```conf
include ~/.local/state/sylphrena/theme/kitty.conf
allow_remote_control yes
listen_on unix:${XDG_RUNTIME_DIR}/kitty-{kitty_pid}.sock
```

4. Recarga en vivo al cambiar wallpaper / esquema / activity:
   - `~/.config/sylphrena/scripts/kitty-reload-colours.sh`
   - Hook en `cli.json` (`theme.postHook` / `wallpaper.postHook`)
   - `scripts/sylphrena-quiet.py` (usado por la shell) llama a esa recarga tras aplicar colores
5. En zsh (ventanas nuevas): `cat ~/.local/state/sylphrena/sequences.txt` en `~/.zshrc`.

Tras el primer arranque de Kitty con `listen_on`, al cambiar de activity (barra, atajos u overview) la paleta de las ventanas abiertas se actualiza sola.

---

## Reloj y temporizadores

Al pasar el ratón por el **reloj** de la barra:

1. **Calendario** (el mismo del dashboard).
2. **Temporizadores**:
   - Presets: **5 / 10 / 20 / 30** min
   - Duración manual (1–180 min): escribe el número y pulsa Enter o +
   - Lista de timers activos con cuenta atrás y cancelar
   - Al terminar: aviso (toast) + sonido del sistema
   - Se **conservan** si reinicias la shell (estado en `~/.local/state/sylphrena/timers.json`)

El reloj lleva siempre la pastilla de fondo; al hover se resalta como el resto de la barra.

---

## Notificaciones

- **Clic izquierdo** en un popup o en la card de la **sidebar**: enfoca/abre la app (workspace, tray o `.desktop`) y cierra la notificación. No hay botón aparte de “abrir”.
- **Hover en la esquina superior derecha** (y la inferior derecha) abre la **sidebar** de notificaciones, no solo utilities.
- Botones de la card: cerrar, acciones de la app (si tienen texto/icono útil) y copiar; se ocultan acciones vacías (p. ej. Teams).
- Compatible con `actionOnClick` cuando hay una sola acción de notificación.
- **Avisos emergentes (toasts)**: salen integrados en el borde de la shell (mismo `PanelBg` que las notificaciones), con animación como los popups de notificación. **Posición** en Nexus → Notificaciones → Avisos emergentes: **Superior** (esquina superior derecha; por defecto) o **Inferior** (esquina inferior derecha). Con la sidebar abierta el aviso queda a su izquierda en ambas posiciones. Config: `utilities.toasts.position` = `"top"` / `"bottom"`.
- **Now playing**: portada con `CoverArt` animado (shape al azar entre cookies / soft burst / sunny / gem / …; sin Oval ni ClamShell). No avisa en vistas previas mudas del listado de YouTube (URL MPRIS de resultados/inicio) ni al re-enfocar Zen con la misma pista; sí al cambiar de canción/vídeo real (`/watch`, `/shorts`, `/live`).
---

## Barra (otros retoques)

- **Tray**: muestra también ítems en estado Passive (p. ej. Teams en idle); highlight al hover / menú abierto; tamaño de icono estable. El **StatusNotifierWatcher** vive fuera de `qs` (`scripts/status-notifier-watcher.py`, arrancado por `scripts/start-shell-with-tray-watcher.sh` desde Hyprland) para que los trays Electron/Flatpak (Teams) sobrevivan a `sylph shell -r` — sin Plasma ya no hay `xembedsniproxy` que rescate el fallback X11.
- **Status icons**: pastilla al hover como el tray; el icono de batería se oculta con el toggle de statusIcons (vanilla).
- **Popouts** de status un poco más anchos para que no se recorten.
- **Reloj** centrado de forma estable en el slot de la barra (geometría vanilla); la pastilla de hover-complemento sigue y el fondo respeta el toggle "Fondo" del Nexus (con Fondo off, solo pinta al hover).
- Indicador de **grabación** bajo el reloj (ver sección anterior).
- La batería se muestra/oculta con el toggle de la lista de statusIcons (vanilla); sin batería, status y popout muestran el estado del **perfil de energía** activo (vanilla).

---

## Nexus y atajos

Ya presentes en este fork respecto a un Sylphrena “vanilla” típico:

- **Atajos de Hyprland remapeables** desde Nexus (genera `sylphrena-binds.lua`), incluyendo teclas **F13+** y **Última ventana** (Super+\` por defecto; cruza escritorios/actividades vía Hyprland).
- **Exportar / importar atajos** (Nexus → Keyboard & mouse, botones «Exportar» e «Importar»): «Exportar» guarda `sylphrena-keybinds.json` (formato `{format, version, binds}`: lo que difiere de los atajos por defecto) en la carpeta que elijas con Seeker; «Importar» lo lee, **sustituye** tus atajos y los aplica. Se ignoran las acciones desconocidas y los valores no válidos, y si dos acciones quedan con la misma tecla solo se conserva la primera. Un fichero que no es de atajos no cambia nada. Sirve para pasar la configuración a otro equipo o tener una copia.
- **Foco del ratón** en Nexus → Keyboard & mouse: al pasar por encima (Hyprland `follow_mouse = 1`) o al hacer clic (`= 2`). Genera `sylphrena-input.lua`.
- **Transición entre escritorios** en Nexus → Activities: cómo cambia la pantalla al moverte entre escritorios y actividades (`workspaceAnimation`): *Fundido* (el de Hyprland, por defecto), *Deslizar*, *Deslizar en vertical*, *Deslizar y fundir* y *Deslizar y fundir en vertical*; con los modos de deslizar aparece la *Velocidad* (`workspaceAnimationSpeed`: lenta, normal, rápida; en Hyprland `speed` es la duración en décimas de segundo, así que menos es más rápido). Genera `~/.config/hypr/sylphrena-animation.lua` (se carga con `pcall(require, "sylphrena-animation")` al final de `hyprland.lua`, tras las animaciones por defecto) y se aplica en caliente. En *Fundido* el fichero no toca tus ajustes.
- Categoría **Activities** en el mapa de teclas (siguiente / anterior / overview).
- Apariencia **unificada en Activities**: una sola página para el comportamiento (iconos, desktops, apps ancladas) y el look — la tarjeta de **Principal** lleva la etiqueta "Look general" (es el estilo que heredan las demás) y cada activity personaliza o hereda (con botón "Usar look de Principal" para volver). Sin página global duplicada: el toggle "Mostrar fondo de pantalla" (switch maestro) vive en General.
- **Extensiones** — solo features opcionales (VPN FortiClient, Juegos/Steam). **Portapapeles y Temporizadores son base** (v0.2): el portapapeles se configura en **Nexus → Panels → Utilities → Portapapeles** (interruptor + tamaño del historial) y los temporizadores en **Panels → Taskbar → Clock**.
- **Status icons honestos**: el badge de updates y la fila de VPN rigen el auto-ocultado con config explícita (`bar.status.onlyShowUpdatesWithUpdates`; VPN atado al complemento) y es visible en `Panels → Taskbar → Status icons → Auto-hide`. La batería quedó **vanilla**: se muestra/oculta con el toggle de la lista "Visible icons" y su popout es el de siempre («No se ha detectado ninguna batería» o «Power profile: %1» en desktops, con el selector de perfiles intacto).
- **Workspaces divididos contenido/apariencia**: mostrar ventanas + special workspaces + max icons viven en **Activities → Escritorios de la barra** (junto al resto del modelo de desktops del fork); la apariencia (número, indicador, fondo, por monitor) se queda en `Panels → Taskbar → Workspaces`, con cross-links navegables entre ambas.
- **Mostrar escritorio**: pulsar en la barra el escritorio que ya está activo desliza todas sus ventanas fuera de la pantalla (las de la mitad izquierda hacia la izquierda, las de la derecha hacia la derecha, con la animación de mover ventana de Hyprland); siguen en ese escritorio y sus iconos siguen en la barra, pero su pastilla pasa de relleno a solo borde para indicar que están ocultas. Pulsarlo otra vez las devuelve a su sitio. Lo hace `scripts/show-desktop.py` (estado en `$XDG_RUNTIME_DIR/sylphrena/`, `Hypr.hiddenWs` en la shell); también `qs -c sylphrena ipc call hypr toggleShowDesktop`. Ya no abre el scratchpad ni atenúa la pantalla.
- **IA del sidebar (fase 1)**: títulos de categoría visibles; orden **Escritorio y apariencia** (Activities, Panels, Complements) → Entrada → **Dispositivos** (Network, Connected devices [Bluetooth + Display inline], Audio) → Apps → Sistema → Acerca de. `smartScheme` en Activities; incrementos volumen/brillo en Audio. Display ya no es página top-level del nav.
- Las páginas del nav llevan **id estable** (`PageRegistry.idxOf`) — los saltos programáticos (Updates → Nexus) ya no dependen de índices hardcodeados.
- Traducciones **español** ampliadas para las cadenas nuevas.

---

## Clipboard (historial)

Popout flotante junto al cursor (estilo Sylphrena), respaldado por **cliphist** + `wl-clipboard`:

- Atajo por defecto: **Super + Shift + V** (Super+V sigue siendo float de ventana; remapeable en Nexus).
- Buscar, favoritos persistentes (estrella a la derecha; vacía solo al hover), borrar entradas o limpiar historial.
- Al elegir un ítem: se copia y se pega con **Ctrl+V** en la ventana que tenía el foco (`wtype`).
- Texto, imágenes del portapapeles (miniatura) y rutas/`file://` a imagen copiadas desde el explorador (también con preview). Un `preview` que acaba en `.jpg` solo se trata como imagen **si el fichero existe** (comprobado en lote tras cada parse; si no, queda como texto).
- Miniaturas decodificadas **al tamaño del thumb** (`sourceSize`), no al del fichero completo; los favoritos de imágenes binarias se emparejan por el **id de cliphist** de origen (el preview genérico `[[ binary data… ]]` ya no provoca estrellas cruzadas).
- Todos los comandos (`delete`, `wl-copy`, `cliphist decode`…) pasan el contenido del portapapeles **como argv (`"$1"`)**, nunca interpolado en la cadena del shell (lección de inyección: `JSON.stringify` es quoting de JS, no de shell).
- Fondo igual que el panel izquierdo (`m3surface` + blur de Hyprland).
- Límite de historial configurable (por defecto **50**) en **Nexus → Complements → Clipboard**.
- Dependencias: `cliphist`, `wl-clipboard`, `wtype`.

---

## Atajos por defecto (activities)

| Acción | Atajo por defecto |
| --- | --- |
| Overview de activities | Super + Tab |
| Activity anterior | Super + Ctrl + ← |
| Activity siguiente | Super + Ctrl + → |
| Última ventana (cualquier escritorio/actividad) | Super + \` (grave) |
| Historial del clipboard | Super + Shift + V |
| Ir a la actividad 1–4 | Super + Ctrl + 1…4 |
| Mover la ventana a la actividad siguiente / anterior (y seguirla) | Super + Ctrl + Shift + → / ← |
| Pantalla completa | Super + F |
| Mover la ventana con el teclado | Super + Shift + flechas |
| Fijar ventana (solo flotantes) | Super + Shift + P |
| Volumen +/−, silencio, silenciar micro | teclas XF86 (antes fijas en `hyprland.lua`; ahora remapeables) |

El resto de atajos de base son los de Caelestia (cerrar Super + C, terminal Super + Q, launcher Super + Espacio, escritorios Super + 1…0, mover a escritorio Super + Shift + 1…0…). La lista completa y los que tengas cambiados salen en el paso «Tus atajos» del asistente de bienvenida, con un botón para editarlos en Nexus.

Cámbialos en **Nexus → Keyboard & mouse**.

---

## OpenCode — plugin file-tree con estados git

**Fuera de la shell** (entorno de agente, no QML): el plugin TUI de OpenCode que muestra el
sidebar de ficheros usa en esta máquina un **fork local** en
`~/.config/opencode/plugins/opencode-file-tree` (se autodescubre; el paquete npm
`opencodev2-file-tree` está fuera de la config).

Extra sobre upstream (`Muyuu-wml/opencode-file-tree` v0.1.3): **colorea carpetas y ficheros
según el estado git**, con glifo delante del nombre:

| Glifo | Estado | Color |
| --- | --- | --- |
| `A` | añadido (staged / nuevo) | verde `diff.text.added` |
| `M` | modificado | ámbar `text.feedback.warning` |
| `D` | borrado | rojo `diff.text.removed` |
| `R` | renombrado/copiado | info `text.feedback.info` |
| `?` | sin seguimiento | verde `diff.text.added` |

- Las **carpetas agregan** el estado de su contenido, prioridad *deleted > modified > added > renamed > untracked* (como los IDEs).
- Un solo `git status --porcelain=v1 -z` por refresco (botón **Refresh**); rutas rebaseadas si el árbol arranca en un subdirectorio; fuera de un repo, árbol normal.
- La fila seleccionada conserva el color primario del tema.
- Cambios en los fuentes posteriormente: `bun run typecheck && bun run build` (bun, no npm) y `opencode service restart`.
- Verificación manual: `test.md` dentro del directorio del plugin. Pendiente de proponer upstream (PR/issue) tras validar.

## OpenCode — tema sincronizado con el esquema

**Fuera de la shell**: el TUI de OpenCode usa un tema `sylphrena` generado desde el esquema
M3 de la activity activa. `scripts/sylphrena-quiet.py` (paso `_sync_opencode_theme`, justo tras
el theming de GTK/iconos) invoca `scripts/generate-opencode-theme.py` + escribe `cli.json`.

- Salida: `~/.config/opencode/themes/sylphrena.json` (formato hue de OpenCode V2, `$schema`
  `https://opencode.ai/theme.json`) + `~/.config/opencode/cli.json` → `{"theme":{"name":"sylphrena","mode":...}}`.
- Genera la paleta del modo que llega (dark/light): gradas tonales M3 vía `materialyoucolor.hct`
  (bins de hue asignados por cercanía: red/orange/yellow/green/cyan/blue/purple + gray anclada a
  onSurface/outline/background) y overrides con los colores del esquema (background/surface
  containers, diff containers, syntax/markdown via keys catppuccin `k*`/`term*`).
- Hot-reload: OpenCode **solo** re-aplica el tema cuando cambia `theme.name` en `cli.json`
  (ni el contenido del theme file ni el resto de settings externos se re-leen en caliente, bugs
  conocidos upstream: issues #815/#37423). Por eso el tema vive en **dos gemelas idénticas**
  (`sylphrena.json` y `sylphrena-alt.json`): cada apply con paleta o modo nuevo flipea `cli.json`
  al otro nombre, lo que fuerza la recarga en los TUI abiertos. Si la paleta no cambió se salta
  (no-op, sin churn). La paleta del otro modo se conserva en la gemela entre runs.
- Peculiaridad del format: los hex DEBEN llevar `#` y **no se aceptan referencias entre tokens**
  (`$text.*`/`$background.*`) en temas de usuario — solo refs `$hue.<nombre>.<step>`; los
  built-in evitan esa validación, los nuestros no (lecciones del debug en este script).

## Lockscreen

La columna derecha del lock (tras CPU/RAM) se parte **35/65**:

- **Arriba**: notificaciones agrupadas por app, con scrollbar cuando no caben.
- **Abajo**: **Sylphrena**, la misma compañera espíritu del viento del greeter Quickshell: saludo por hora, líneas idle a máquina de escribir, orbe SoftBurst y estados al escribir la contraseña, fallar PAM o desbloquear.

El panel del lock usa tokens Material de la sesión (`Tokens` / `Colours`) y PAM (`lock.pam`), no el `Theme`/`Auth` del greeter.

---

## Auriculares Bluetooth: modo de audio

El popout de Bluetooth (barra) es una lista de una línea por dispositivo: **el icono es el botón de
conectar/desconectar** (círculo de acento = salida de audio activa, tono suave = conectado, sin círculo =
desconectado), nombre, batería (un anillo con el porcentaje dentro; los AirPods muestran L · estuche · R),
un selector pequeño **Música / Llamadas / Auto** (solo iconos) y el botón de olvidar. El engranaje junto al título
abre una ventana normal de Nexus en Dispositivos conectados. Los modos:

- **Música**: A2DP fijo (alta calidad, sin micro).
- **Llamadas**: perfil de manos libres fijo (micro siempre disponible). Sirve para Teams: solo lista
  el micro si existe al **entrar** en la reunión, así que conviene tener este modo antes de unirte.
- **Auto**: WirePlumber cambia a manos libres cuando una app graba y vuelve después (comportamiento por defecto).

Implementación: `services/BluetoothAudio.qml` (lee `pactl -f json list cards`, escucha `pactl subscribe`,
aplica con `pactl set-card-profile`). «Auto» es el ajuste **global** de WirePlumber
`bluetooth.autoswitch-to-headset-profile` (se guarda con `wpctl settings --save`), no es por dispositivo.

**Página del dispositivo (Nexus → Dispositivos conectados → engranaje del dispositivo).** Con unos auriculares
conectados aparece una sección **Audio**: selector de modo (Música / Llamadas / Auto) con su descripción, el canal
actual (alta calidad o llamadas, con códec), la calidad de la música (AAC / SBC-XQ / SBC, si el dispositivo ofrece
varios) y el volumen de la salida con su silencio (el popout no los tiene: el volumen y el silencio solo se
tocan aquí). En **Batería**, los AirPods muestran los tres anillos (L, estuche y R) en una franja. Los componentes
(selector de modo, anillos, franja de baterías, volumen) son compartidos y viven en `components/bluetooth/`.

**Batería de AirPods.** BlueZ no la publica, así que `scripts/airpods-battery.py` la lee del propio auricular por el
canal de accesorios de Apple (L2CAP, solo lectura, ~2 s) y `BluetoothAudio` la sondea cada 2 min mientras haya unos
AirPods conectados. El popout muestra el nivel del auricular más bajo. Si el derecho no reporta (fuera de uso o en el
estuche), se usa el que sí lo hace. Para otros dispositivos se sigue usando la batería de BlueZ.

**mSBC desactivado (MediaTek).** El adaptador Bluetooth de este equipo (`0e8d:0616`) rompía el enlace SCO de los
AirPods con el códec de manos libres mSBC (`SCO packet for unknown connection handle`, nodos en `error`, micro
mudo). `~/.config/wireplumber/wireplumber.conf.d/52-bluetooth-no-msbc.conf` pone `bluez5.enable-msbc = false` y
fuerza CVSD (voz más «telefónica», sin tocar la música). Fichero fuera del repo: para revertir, borrarlo y
`systemctl --user restart wireplumber`.

## Carrusel de widgets del dashboard

El hueco central del dashboard (antes calendario/hidratación según un interruptor) es un **carrusel**: un
widget a la vez. Se cambia con los puntos (superpuestos abajo), la rueda del ratón o arrastrando en
horizontal (en el carrusel el calendario no consume la rueda: `Calendar.scrollable`; el popout del reloj sí); sin rotación automática. Con un solo widget activo no hay controles.

- **Ajustes**: `Nexus → Panels → Dashboard → Carrusel de widgets`. Cada widget es una fila con flechas ↑/↓ para
  **ordenarlo**; Hidratación lleva además su interruptor y sus ajustes desplegables (meta, intervalo, presets).
- **Nada viene activado por defecto**: cada widget (calendario incluido, `dashboard.calendarEnabled`) tiene su interruptor. Sin ninguno activo el carrusel muestra el botón **«Activa widgets»**, que abre Nexus directamente en `Panels → Dashboard`.
- **Tareas** (extensión `tasks`, se activa en el carrusel; `extensions.enabled`): checklist con lista vertical desplazable. Se crean escribiendo y pulsando Enter (o `+`), se marcan con el círculo, se eliminan con la ✕ que aparece al pasar el cursor, y las completadas bajan a una sección **«Completadas (n)» plegable** (con botón para vaciarlas). Al pulsar el campo, el panel toma el teclado y se mantiene abierto hasta `Esc` o clic fuera. Datos en `~/.local/state/sylphrena/tasks.json`; desactivar el widget no borra las tareas.
- **Hidratación** on/off sigue siendo `addons.hydration.enabled` (apagarlo detiene también recordatorios y seguimiento).
- Config: `dashboard.widgetOrder` (lista de ids, por defecto `["calendar","hydration"]`). Ids desconocidos se ignoran y
  los que falten se añaden al final, así los widgets nuevos no rompen configs antiguas.
- Para añadir un widget: entrada en `services/DashWidgets.qml` (+ `isEnabled`), caso en
  `modules/dashboard/dash/WidgetCarousel.qml` y, si tiene opciones, su tarjeta en `modules/nexus/pages/panels/DashboardPanel.qml`.

## Plugin C++ (build user-local)

La shell **carga el plugin compilado en `~/.local`**, no el del paquete AUR (que vive en
`/usr/lib/qt6/qml` y no lo pisamos):

- Build **desde la raíz del repo** (`~/.config/quickshell/sylphrena`, su `CMakeLists.txt` ya trae
  `cmake_minimum_required`): `cmake -B build -DCMAKE_BUILD_TYPE=Release -DENABLE_MODULES=plugin
  -DCMAKE_INSTALL_PREFIX=$HOME/.local` → `cmake --build build` → `cmake --install build`.
  Con `ENABLE_MODULES=plugin` no se sobrescribe `shell.qml` (la trampa del install solo aplica al
  módulo `shell`); `build/` está gitignored.
- La shell lo engancha con el pragma `//@ pragma Env QT_ADDITIONAL_PACKAGES_PREFIX_PATH=/home/manu/.local/lib/qt6/qml`
  en `shell.qml` — verificar tras un restart: el proceso debe mapear `~/.local/lib/qt6/qml/Sylphrena/…/*.so`.
- Cambios C++ concretos: `Requests.get` con **transfer timeout de 15 s** (sin él, una conexión
  colgada dejaba el contador `pending` a 1 para siempre y el spinner de Steam no paraba).

## Notas

- Instalación y listado de features: [README.md](./README.md). Historial: [CHANGELOG.md](./CHANGELOG.md).
- Algunas piezas siguen en evolución; si algo no aparece tras actualizar, reinicia la shell (`sylph shell -r`) y comprueba los `require(...)` de Hyprland.
- `scripts/sylphrena-quiet.py` evita spamear OSC a todos los PTY al cambiar el tema (recarga Kitty, sync Papirus en qt6ct, GTK/`colors.css`).
- `scripts/apply-activity-style.py` aplica wallpaper + esquema de la activity en un solo proceso.
