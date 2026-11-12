# Changelog

Cambios relevantes de este fork respecto a releases internas. El detalle de uso está en [FEATURES.md](./FEATURES.md).

## 0.5.4 (2026-11-12)

- **Aviso de Sylphrena:** título «Actualizaciones de Sylphrena», como el de las extensiones.
- **Comprobación de actualizaciones unificada:** Sylphrena y sus extensiones se comprueban con el mismo intervalo que los paquetes del sistema (el de Nexus → Actualizaciones, 30 minutos por defecto) y con el mismo botón de refrescar; ya no cada minuto.

## 0.5.3 (2026-11-12)

- **Notificaciones sin texto:** en el panel lateral ya no muestran «No body here! :/».
- **Notificaciones que se abren desplegadas:** entran ya desplegadas; antes se desplegaban mientras entraban y el título se cruzaba con el nombre de la app y la hora.
- **Aviso de extensiones actualizables:** título «Actualizaciones de extensiones», que cabe (el anterior se cortaba).
- **Actualizar una extensión recién publicada:** `ext.py update-hub` lee el catálogo por la API de GitHub, porque la caché del fichero tardaba minutos en dar la versión nueva y volvía a instalar la vieja; la comprobación de cada minuto pide el catálogo sin caché.
- **Actualizar sin Flatpak (o sin ayudante del AUR):** «Actualizar» se saltaba con error al no encontrar `flatpak` y ya no actualizaba Sylphrena ni las extensiones; ahora salta lo que no está instalado y lo dice en el registro.

## 0.5.2 (2026-11-12)

- **Órdenes de extensiones con `sylph ext <id> <orden>`:** una extensión declara sus órdenes en el manifiesto (`contributes.commands`) y su servicio las responde; `sylph ext <id>` las lista. Hidratación trae `show`, `add <ml>` y `status`.
- **Barra de progreso en las notificaciones:** las emergentes y las del panel lateral muestran una barra de progreso Material cuando la notificación la trae (el aviso estándar `value` de cualquier app, como una descarga, o `localProgress` en las de la shell y sus extensiones).
- **Esquina inferior derecha sin panel lateral:** con el panel lateral desactivado abre los interruptores rápidos solos (antes hacían amago de salir y se escondían), y un aviso emergente se aparta a su izquierda acompañando su animación.
- **Avisos de versiones nuevas:** se recuerdan entre reinicios (`~/.local/state/sylphrena/updates-announced.json`); cada versión se avisa una sola vez.
- **Dashboard sin el gato:** fuera el gato animado de la tarjeta de multimedia de la base original (el GIF y sus opciones `paths.mediaGif` y `general.mediaGifSpeedAdjustment`, que se borran solas de las configuraciones existentes); de paso deja de correr el detector de ritmo que solo lo animaba.
- **Opciones heredadas fuera:** las de la tira de escritorios antigua de la base que ya no hacían nada con las actividades («Mostrados», «Mostrar desocupados», «Ventanas en escritorios especiales» y la forma de los escritorios especiales), con su código; se borran solas de las configuraciones existentes. «Por monitor» pasa a «Atenuar los escritorios de otro monitor», que es lo que hace.
- **Vista previa de ventanas:** al pasar el ratón por el icono de una app en la barra se ve una miniatura en vivo de su ventana (pulsar lleva a ella); activable en Nexus → Paneles → Barra de tareas → Escritorios.

## 0.5.1 (2026-11-12)

- **Sylphrena y sus extensiones en la lista de actualizaciones:** dos categorías más junto a pacman, AUR y Flatpak (Sylphrena, con su orbe, y Extensión). «Actualizar» las pone al día en segundo plano después del sistema, con la misma contraseña y el registro en Nexus; si se actualiza la shell, se reinicia sola. Las extensiones se actualizan igual que en Things (`ext.py update-hub`).

## 0.5.0 (2026-11-12)

- **Avisos de versión nueva:** en un equipo instalado con los paquetes, la shell comprueba la última release de la shell, la CLI, Seeker y Things y avisa (con el orbe de Sylphrena) cuando hay una más nueva: el icono de actualizaciones de la barra, una franja en su popout y una tarjeta en Nexus → Actualizaciones con las notas de la release. «Actualizar» abre un terminal con el instalador en modo `--update`. De momento comprueba cada minuto (pruebas); se espaciará.
- **El instalador instala releases:** cada paquete se compila desde la última release de su repo (`SYLPHRENA_REF=<tag>` en los PKGBUILD) y se actualiza si va por detrás; `--main` compila lo último de `main` y `--update` solo pone al día lo instalado. Seeker y Things pasan a numerarse por release (`0.1.2.r0.g…`).
- **Primer arranque en un Arch nuevo:** la shell arranca sola (faltaba `python-gobject`), las rutas apuntan a la shell instalada y no al clon, Hyprland usa la distribución de teclado del sistema y no enseña su propio fondo mientras arranca la shell; al terminar, el instalador pide reiniciar. Seeker y Things se abren desde el lanzador (los `.desktop` del paquete apuntaban a `~/.local/bin`).
- **Instalador más robusto:** `libcava` desde el AUR, compilar sin `fish`, compilación limitada a la memoria y aviso si se queda sin ella, `makepkg` sin volver a pedir la contraseña, carpetas de compilaciones anteriores que no se podían borrar.

- **Capturas por defecto:** `Impr Pant` congela la pantalla y copia la zona elegida al portapapeles; `Alt+Impr Pant` la abre para editarla.
- **Menú de sesión:** el orbe animado de Sylphrena sustituye al personaje animado de la base original (se quitan el GIF y sus opciones `paths.sessionGif` y `general.sessionGifSpeed`, que se borran solas de las configuraciones existentes).
- **Instalador:** recomienda el navegador Zen (del AUR); viene marcado solo si no hay otro navegador instalado.
- **Teclado en Nexus:** Idioma y región → Teclado permite elegir las distribuciones (y variantes), cuál es la principal y el atajo para cambiar entre ellas.
- **Atajos:** los de Sylphrena sustituyen a los que `hyprland.lua` tuviera en las mismas teclas (en un sistema nuevo `Super+Q` abría dos terminales).
- **Instalador:** ya no ofrece extensiones (al terminar indica que se instalan desde Things); limita la compilación a la memoria disponible y avisa si se queda sin ella; `makepkg` ya no vuelve a pedir la contraseña a mitad de instalación.
- **Mostrar escritorio:** pulsar en la barra el escritorio activo desliza sus ventanas fuera de la pantalla (izquierda/derecha según su mitad) y otra pulsación las devuelve idénticas; el pill pasa a solo borde mientras están ocultas. Ya no abre el scratchpad ni atenúa la pantalla.
- **Transiciones de escritorio y de actividad:** ajustes nuevos en Nexus → Activities, uno para moverte entre escritorios (por defecto deslizar en vertical) y otro para saltar de actividad (por defecto fundido); estilos fundido/deslizar/deslizar y fundir, también en vertical, y velocidad.

## 0.4.0 (2026-11-12)

- **Instalador de Arch (`./install.sh`):** de un Arch con Hyprland a la experiencia completa en una sola sesión de terminal. Escanea, enseña el plan con el porqué de cada cosa, confirma, y lo hace con una contraseña: herramientas base, `yay`, librerías del AUR, los cuatro paquetes (de GitHub con `makepkg` mientras no estén en el AUR), recomendados, enganche a Hyprland (`setup-hyprland.py`), ajustes del primer arranque y la pantalla de login. Se puede repetir.
- **Pantalla de login (`install-system.sh`):** instalaba los ajustes de `logind` (sin la espera de 10 s de pantalla negra tras escribir la contraseña) y justo después los borraba, por un resto del renombrado; ahora los deja puestos y solo quita los nombres antiguos (`caelestia-*`). Además deja a `greetd` como gestor de sesiones (desactiva el que hubiera, sin pararlo) y avisa si faltan `rsync`, `python3` o `greetd`.
- **Paquete de la shell:** `papirus-icon-theme`, `adw-gtk-theme` y `swappy` son dependencias obligatorias (la shell escribe la configuración de los dos primeros y la captura normal abre `swappy`); `gpu-screen-recorder` pasa a opcional del paquete y el instalador lo ofrece.

## 0.3.1 (2026-11-12)

- **Things, Seeker y la pantalla de login hablan tu idioma:** su código está ahora en inglés y cada idioma es un catálogo JSON (`i18n/es.json`; la pantalla de login, `greeter/i18n/es.json`). Un idioma sin catálogo se ve en inglés. Antes estaban escritos en español, sin más idioma posible. Sus comprobadores: `scripts/check-i18n.py`.
- **Nada personal en el repo:** la pantalla de login ya no trae un nombre ni unas coordenadas del tiempo (salen de la cuenta y del ajuste del tiempo de Nexus) y la pantalla de bloqueo saluda con el usuario del sistema.
- **Things:** «Usar la del hub» para cambiar una copia local por la del hub (así se puede actualizar).
- **Hub:** una versión ya publicada no puede cambiar de zip (la comprueba la CI contra `origin/main`); `tasks` 0.1.2 y `games` 0.1.4 piden Sylphrena 0.3.
- **Tests:** `unittest` para `ext.py`, `install-extension.py`, `setup-defaults.py`, `setup-kitty.py`, `build.py` y los scripts de Juegos. Un zip hecho por un script (sin tipo de fichero en los permisos) ya no se rechaza como «fichero especial».

## 0.3.0 (2026-11-11)

- **Paquetes del AUR:** `sylphrena-shell-git`, `sylphrena-cli-git`, `seeker-git` y `things-git` (PKGBUILD y `.SRCINFO` en el `packaging/` de cada repo; guía en `packaging/README.md`). El paquete instala la configuración en `/etc/xdg/quickshell/sylphrena` con los permisos de ejecución, y el selector de ficheros encuentra Seeker también en el PATH.
- **Configuración inicial:** una instalación nueva arranca con los ajustes recomendados de Nexus, una sola actividad (Principal, dos escritorios) y su fondo, incluido en `assets/wallpapers/` (`setup-defaults.py`; nunca pisa una configuración existente).
- **Instalar una extensión desde un zip** ya vuelve, pero en **Things** (sección Sylphrena → «Instalar desde zip»: selector de Seeker, vista previa con `ext.py inspect`, confirmación; queda como «local») y en terminal con `sylph ext install <zip>`. Things pide el catálogo al hub al abrir (la caché ya no lo deja desfasado una hora).
- **Atajos por defecto ampliados** (pantalla completa, mover ventana con el teclado, fijar, ir a la actividad N, mover la ventana a la actividad siguiente/anterior, volumen y micro remapeables) y un paso nuevo del asistente de bienvenida, «Tus atajos»: tabla de los que están en uso (se actualiza al cambiarlos en Nexus) y botón «Editar en Nexus».
- **Atajos: exportar e importar** la configuración actual desde Nexus → Keyboard & mouse (fichero JSON `sylphrena-keybinds.json`; la importación valida y sustituye). El selector de ficheros (`FileDialog`) admite `mode: "folder"`.

- **Asistente de bienvenida** (con una invitación a crear extensiones propias y un enlace al hub; ventana de 4 pasos, con el orbe animado: grande y centrado en el primero, vuela al lado del título en los siguientes, sale sola en el primer arranque y se reabre desde Nexus → Acerca de): qué es Sylphrena y quién la hace, qué ofrece y apps de la familia. El paso de apps (Seeker, Things, kitty) es informativo: las instalará el paquete base. Servicios nuevos `Companions` y `Welcome`. Nexus → Extensiones gana la fila «Buscar más en Things».
- **Contrato con Things** (fase 0): `apiVersion` y `requires.sylphrena` en el manifiesto (una extensión incompatible se lista pero no se carga, con el motivo); recibo `.source.json` para distinguir las del hub de las locales; comandos IPC `extensions list | rescan | enable | disable | prepareRemoval`; `scripts/ext.py` (instalar/quitar desde terminal, base de `sylph ext`). Corregido: la versión que lleva compilada el plugin se quedaba en `0.1.0` por la caché de CMake. Detalle en `AGENTS.md` («Contrato con Things»).
- **La shell se adelgaza (fase 2):** instalar, actualizar y quitar extensiones pasa a **Things** (sección «Sylphrena») y a `scripts/ext.py`. Nexus → Extensiones queda en «instaladas + interruptor + ajustes + Buscar más en Things»: se retiran «Instalar desde zip», la tarjeta de contraseña, la gestión de piezas de sistema y el botón de eliminar. Se conserva la comprobación (sin root) de las piezas de sistema, el aviso de por qué una extensión no corre y `prepareRemoval`. IPC nuevo `extensions reload`; `enable` devuelve `pending` si la extensión aún no está listada.
- **Se quita la extensión de batería del ratón Razer** (`razer-mouse`) y el enganche `resourceRing`: acoplaba la shell a `synapsex` y se reimplementará mejor más adelante. El dashboard recupera siempre el anillo de almacenamiento. Al arrancar, la migración de configuración quita `addons.razerMouse` y el id `razer-mouse` de `extensions.enabled`.

- **Empaquetado (fase 3):** kitty se conecta solo a los colores de la shell (`setup-kitty.py`: bloque marcado en `kitty.conf` con copia, plantilla y script de recarga incluidos en el repo: `assets/kitty/`, `scripts/kitty-reload-colours.sh`); `PKGBUILD` de Things (rama `feature/pkgbuild` de su repo) y borrador de `packaging/PKGBUILD` de la shell con las dependencias duras (`qt6ct`, `cliphist`, `wl-clipboard`, `wtype`, fuentes, y Things, Seeker y kitty) y recomendadas (Papirus, `adw-gtk-theme`); `cmake --install` del módulo `shell` ahora instala también `scripts/`, `extensions/` y `greeter/`.

- **Tareas, Hidratación y Juegos pasan al hub** (mismos ids: ajustes y datos intactos); se instalan con Things o `ext.py`. Sus cadenas viajan en su `i18n/es.json` (con plurales) y se quitan del `es.po` de la shell.

## 0.2.0 (2026-11-11)

### Extensiones

- La shell se separa en **base** y **extensiones**. Una extensión es una carpeta (`extensions/<id>/`, o en `~/.local/share/sylphrena/extensions/`) con `manifest.json`, un servicio y sus componentes; se activan en Nexus (`extensions.enabled`, nada por defecto) y se cargan/descargan en caliente. Enganches: `service`, `widgets`, `settings`, `resourceRing`, `statusIcons`, `popouts`, `dashboardTabs`, `vpnProviderType`. Guía: `AGENTS.md` («Extensiones») y `docs/examples/extension-spike/`.
- **Migradas**: Tareas, Hidratación (widgets), batería del ratón Razer, VPN FortiClient (antes «Madison VPN») y Juegos (Steam) (complementos). Su configuración se migra sola (`scripts/migrate-config.py`).
- **Base**: Portapapeles (ajustes en Panels → Utilities) y Temporizadores dejan de ser complementos. Calendario como único widget de serie.
- **VPN unificada y FortiClient genérico**: una extensión puede aportar un **tipo** de proveedor a la VPN de Nexus → Red (`vpnProviderType`). Añadir proveedor deja elegir «Comandos» (lo de siempre) o **FortiClient**, con su formulario: OTP opcional, certificados, TLS antiguo, host de comprobación, DNS/dominios y entradas de `/etc/hosts`. Varias conexiones posibles. Lo no secreto va en `shell.json` (`type` + `options`); la contraseña solo en `~/.config/sylphrena/vpn/<id>.conf` (600). El túnel usa un ayudante root genérico en el repo (`sylphrena-fortivpn`) que valida el fichero y ya no tiene nada de una red concreta.
- La página de Nexus **Complementos** pasa a llamarse **Extensiones** (id `extensions`, `ExtensionsPage.qml`). Arriba lleva la fila «Instalar desde zip» con un botón «Examinar» (y la tarjeta de contraseña debajo cuando hace falta) y debajo la sección «Instaladas». El Reloj ya no enlaza a ella para los Timers, que se activan en el propio Reloj.
- La tarjeta de cada extensión muestra siempre su descripción (ya no el estado en vivo ni el aviso de «desactivado»); el estado lo enseña cada extensión donde quiera.
- «Añadir proveedor» → FortiClient: la primera fila permite **importar conexiones desde un fichero** (el que exporta la extensión), y el formulario de una conexión nueva ya no se rellena solo con `~/.config/openfortivpn/config`. Borrar una conexión limpia también las copias de certificados que importó la extensión.
- Eliminar una extensión borra también sus conexiones VPN (con sus ficheros); desactivarla las conserva y las marca como «extensión desactivada».
- Instalar una extensión desde zip (nueva o actualización) la activa al terminar.
- **Instalar extensiones desde zip** (Nexus → Extensiones): se valida el zip y se instala en `~/.local/share/sylphrena/extensions/`, sin reiniciar; reinstalar actualiza y las instaladas así se pueden eliminar. Las extensiones externas traen sus traducciones (`i18n/<lang>.json`), que `Tr` usa cuando la shell no tiene la cadena. **VPN FortiClient sale del repo** de la shell: se distribuye como zip aparte.
- **Extensiones con piezas de sistema** (manifiesto `system`): lo que necesitan como root se instala **con el zip** (la contraseña se pide al instalarlo y va a `sudo` por stdin) y se quita al **eliminar** la extensión. Si queda a medias, su tarjeta ofrece «Completar». Instalar es independiente de activar. FortiClient instala así `openfortivpn`, su ayudante y la regla de sudoers; `install-system.sh` queda solo para la base (greeter).
- Corregido: el paso del greeter de `install-system.sh` se paraba («Both … are real directories») porque tras el cambio de nombre comparaba su directorio consigo mismo. Las cadenas de los manifiestos de extensión vuelven a traducirse (`scripts/manifest-strings.py` en `trs.fish raw`). El popout de la barra solo conecta y desconecta.
- Sin rutas ni datos personales en el repo (`shell.qml` ya no lleva `/home/<usuario>`).

## 2026-11-10

### Dashboard

- **Carrusel de widgets** en el centro del Panel: calendario e hidratación (más los que vengan), con puntos, rueda y arrastre, orden configurable y sin rotación automática. Ajustes en `Panels → Dashboard → Carrusel de widgets`; **Hidratación** se movió allí desde Complementos con los mismos ajustes. Nuevas opciones `dashboard.widgetOrder` y `dashboard.calendarEnabled` (requiere reinstalar el plugin); nada activado por defecto: sin widgets aparece «Activa widgets», que abre Nexus en Panels → Dashboard. La rueda cambia de widget (`Calendar.scrollable`).
- **Widget de Tareas** (`dashboard.tasksEnabled`): checklist con scroll vertical; crear, completar y eliminar; las completadas pasan a una sección plegable. El panel toma el teclado mientras se escribe (`ScreenState.dashboardTyping`).

### Complementos

- **Batería del ratón Razer** (`addons.razerMouse`): lee la batería del Basilisk V4 Pro con `synapsex-cli` y la muestra en el dashboard en el hueco de almacenamiento; aviso al 20 % y 10 %.

### Apps claras

- Las apps **Qt** (Transmission…) siguen el modo claro (paleta qt6ct clara + Papirus-Light) y las GTK usan Papirus-Light (los iconos oscuros no se veían). Corregido un `NameError` en `_sync_qt6ct` que cortaba el apply.

## 2026-11-09

### Bluetooth

- Popout de Bluetooth: selector **Música / Llamadas / Auto** por dispositivo conectado (perfil A2DP/manos libres) con línea de estado (códec y micro).
- Iconos de notificación recibidos como URL `file://` (Claude) ya no salen como el cuadro de «icono no encontrado».
- Iconos de la bandeja oscuros (p. ej. Claude) se detectan midiendo el icono y se fuerzan a claro.

## 2026-11-03

### Juegos

- Heatmap del panel: clic en un día con sesión (o logro) filtra Sesiones / Total / Más larga a ese día; otro clic o cambiar de mes vuelve al mes completo.

### Pantalla

- Nexus → Display: resolución y frecuencia en selects separados (Hz de la resolución actual). Al aplicar modo/escala se espera a que `hyprctl eval` termine antes de refrescar (antes parecía que el clic no hacía nada).

### Activities

- Overview: chip discreto de mute en miniaturas de ventanas con audio (PipeWire, match por PID/clase); clic silencia/reactiva esa app.
- Quitado el interruptor **Activar actividades**: siempre on (puede haber solo Principal o varias). La barra usa siempre las pills; `activities.enabled` se fuerza a `true` al arrancar (migración).
- Clic derecho en el icono de una activity de la barra: popout integrado (lóbulo del borde) con **Cerrar todas las ventanas**.
- Overview (**Super + Tab**) ya no se bloquea con una ventana a pantalla completa (los drawers sí siguen gated). Con Exclusive keyboard focus y salida temporal de fullscreen (p. ej. juegos XWayland) el overlay recibe ratón/teclado; al cerrar en el mismo escritorio se restaura.

### Utilities / grabación

- Grabación integrada en Interruptores rápidos: última fila a ancho completo con «Grabar pantalla» (pantalla completa) y flecha para desplegar modos, lista y controles. Mientras graba se fuerza expandida.

### Notificaciones

- Avisos enviados vía `notify-send`: si traen `desktop-entry` (p. ej. Timeshift) el grupo usa el nombre del `.desktop` en vez de «notify-send». Se quita el icono genérico azul de información; si hay icono de app se usa solo ese, y si no el glifo Material `notifications`.

## 2026-11-02

### Sesión

- Menú de apagado (y controles del lock): **Suspender** sustituye a Hibernar (icono `bedtime`, comando `suspend`). Hibernar no funcionaba en este equipo.

### Now playing

- No avisa en vistas previas mudas del listado de YouTube (la URL MPRIS sigue siendo la página de resultados/inicio, no `/watch`). Tampoco si el reproductor reporta volumen 0. Al enfocar Zen ya no se repite el aviso de la misma pista (el rebind MPRIS del navegador ya no cuenta como canción nueva).
- El aviso de now playing muestra la portada con el mismo `CoverArt` animado del panel multimedia (sin arco de progreso). Cada aviso elige al azar una shape redondeada (cookies, soft burst, sunny, gem, ghostish, clover, pill, pentagon; sin Oval ni ClamShell).

### Toasts integrados en el borde

- Los avisos emergentes (Caps Lock, DnD, VPN, etc.) dejan de flotar como tarjeta suelta: usan el mismo `PanelBg` que las notificaciones y salen en la esquina superior derecha, con el borde de la shell extendiéndose alrededor del aviso.
- Animación igual que los popups de notificación (`modules/notifications/Content.qml`): `ListView` con entrada/salida deslizando en horizontal, `move`/`displaced` para los hermanos y altura del lóbulo con la curva expresiva espacial. Siguen alimentados por `Toaster` y nunca entran en la lista de notificaciones.
- Con la sidebar abierta el aviso sale **al lado** de ella en ambas posiciones (anclado a su borde izquierdo, unido al borde superior o inferior), en vez de meterse encima del panel; la sidebar lo empuja al abrirse. Solo se apila sobre los popups de notificación / utilities con la sidebar cerrada.
- Nueva opción **Posición** (Superior / Inferior) en Nexus → Notificaciones → Avisos emergentes (`utilities.toasts.position`, requiere el plugin recompilado). En inferior el aviso sale en la esquina inferior derecha unido al borde inferior / utilities.
- Aviso arriba apilado sobre los popups de notificación: unión recta (sin protuberancia ni costura). Shader de blobs: en la zona de mezcla solo pinta el dueño del píxel cuando su renderer lo cubre (antes el borde antialiasado se pintaba dos veces y dejaba un escalón subpíxel entre lóbulos). Incluye al marco: sus franjas llegan 2×smoothing más allá del borde interior, y donde terminaban (y≈50) el canto vertical de los lóbulos pasaba de doble a simple pintado con un escalón de ~0,25 px. Los empates (aviso apilado sobre el panel de notificaciones, filete lóbulo↔marco) se resuelven igual en todos los renderers (marco y luego índice menor), y los blobs con `exclude` mutuo ya se ven entre sí (la máscara sigue evitando el smin): antes ninguno sabía del otro y ambos pintaban los 4 px de solape. La regla de dueño único solo se aplica a la franja antialiasada: en el interior opaco, durante una animación los renderers pueden discrepar (movimientos subpíxel sin propagar, deform por frame) y si ambos cedían quedaba una línea de 1 px al crecer el aviso. Solape aviso↔panel subido a 12 px.
- Borde superior: escalón subpíxel en el ancho del dashboard cerrado (su blob oculto, aparcado dentro del borde, hundía la pared interior). Los `PanelBg` de paneles ocultos ya no participan ni se renderizan.

## 2026-10-31

### Activities / esquema dinámico

- `apply-activity-style.py` se había quedado con imports viejos (`convert_gif` / `is_valid_image`) y fallaba al aplicar wallpaper → el esquema `dynamic` no regeneraba el acento desde el fondo.
- Al elegir/regenerar `dynamic`, el apply vuelve a sincronizar el wallpaper de la activity (no el thumbnail de otra) y fuerza `update_colours`.

## 2026-10-30

### Seeker (explorador)

- Nuevo explorador **Seeker** (etiqueta **Archivos**, repo `~/Desarrollo/seeker`, Qt6 QML): default en `apps.explorer`, Super+E y `FileManager1`.
- `sylphrena-quiet.py` escribe `~/.config/seeker/theme.json` en cada apply de esquema (hot-reload M3 en Seeker).
- Thunar deja de ser el default; sigue usable como alternativa.
- Eliminado el explorador QML embebido (`FolderContents`/`HeaderBar`/…): wallpaper, avatar e icono de `.desktop` pasan por `FileDialog` → Seeker `--pick`.

### Apps (`.desktop`)

- El diálogo **Editar aplicación** (launcher y Nexus → Apps → detalle, botón de lápiz) edita también nombre genérico, `Exec`, categorías, palabras clave, `StartupWMClass`, directorio de trabajo y terminal. Las claves vacías que no existían no se escriben en el override.
- Detalle de app en Nexus: muestra `Exec`, directorio de trabajo, clase de arranque, icono, categorías, palabras clave, terminal y ruta del `.desktop`.

### About / SylphOrb

- Página **Acerca de**: el hero usa el orbe SoftBurst animado (mismo de lock/greeter) en lugar del `AnimatedLogo` SVG estático.
- Nuevo `components/SylphOrb.qml` (+ gemela `greeter/components/SylphOrb.qml` con tokens Theme): lock y greeter dejan de duplicar el bloque del orbe.

### Tray

- StatusNotifierWatcher persistente (`scripts/status-notifier-watcher.py`) fuera de `qs`, arrancado antes de la shell vía `scripts/start-shell-with-tray-watcher.sh`. Los iconos Electron/Flatpak (Teams) dejan de desaparecer tras `sylph shell -r` ahora que Plasma ya no aporta `xembedsniproxy`.

### Polish (deep audit)

- `steam-activity.py` snapshot: entries with legacy/`[minutes, 0]` timestamps are **rebaselined** (no residual from `since=0`), so heatmap deltas stop being swallowed by tracked sessions after the next Games reload.
- Area picker clipboard-only capture copies via argv (`$1`), not shell string concat.
- Notification popup expiry timer only runs while `popup` is true (history entries idle; re-show re-arms).

### Nexus — reorganización del sidebar (fase 1)

- Categorías visibles en el nav; agrupación tras feedback Jorge: **Escritorio y apariencia** (Activities, Panels, Complements), Entrada, **Dispositivos** (Network, Connected devices, Audio), Apps, Sistema, Acerca de.
- Orden sidebar: Activities → Panels → Complements → Keyboard & mouse → Network → Bluetooth → Audio → Apps → Updates → Language & region → Tuning (`id: services`) → About.
- **Display** (Hz/escala/VRR) va **inline** en **Connected devices** (mismo nivel que Bluetooth; sin subpágina ni entrada sola en el sidebar).
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

- **Nexus → Extensiones**: toggles Madison VPN + Timers (iconos `verified_user` / `timer`).
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
