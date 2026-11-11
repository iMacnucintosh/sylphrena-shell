# Plan: separar la base de Sylphrena de sus extensiones

Documento de trabajo para el agente que lo implemente. Léelo entero antes de tocar nada, junto con
[AGENTS.md](../AGENTS.md) (convenciones del repo, trampas conocidas). Si algo de este plan choca
con lo que encuentres en el código, **para y pregunta al usuario**; no improvises un rediseño.

Estado: **cerrado: publicado como `v0.2.0` (PR #34, 2026-11-11)**. Siguiente: [PLAN-0.3.md](./PLAN-0.3.md). Fases 0–5 ejecutadas el 2026-11-10 en `dev/0.2` (ver [PLAN-LOG.md](./PLAN-LOG.md)). Pendiente: que el usuario pruebe y, si todo va bien, borrar la copia de seguridad, abrir la PR `dev/0.2` → `main` y crear el tag `v0.2.0`.

**Rama de trabajo: `dev/0.2`.** Todo este refactor es la versión **0.2.0** de Sylphrena y se
desarrolla en esta rama de larga duración. **`main` no se toca** hasta que el conjunto sea estable:
se queda en la línea 0.1.x, que es lo que el usuario puede seguir usando si algo sale mal. Cada
fase es una rama `feature/*` que sale de `dev/0.2` y se fusiona **en `dev/0.2`** (nunca en `main`).
Solo al terminar la fase 5, y con el visto bueno del usuario, se abre la PR `dev/0.2` → `main` y se
crea el tag `v0.2.0` (el build lee la versión de los tags `v0.*`; no crees el tag antes).

---

## 1. Objetivo

Sylphrena es un fork de Caelestia (shell Quickshell/QML para Hyprland). Hoy es un único repo donde
conviven la shell base y funciones personales u opcionales. Queremos:

1. Una **base** estable e instalable en cualquier equipo (a futuro, paquete AUR), sin nada personal.
2. Que todo lo opcional sea una **extensión** claramente separada, que se pueda quitar sin romper la base.
3. Dejar el terreno preparado para, más adelante: paquete AUR, asistente de primer arranque,
   catálogo de extensiones en Things e instalación de extensiones desde una carpeta local.

**Este plan cubre solo los puntos 1 y 2** (fases 0–5). El punto 3 está descrito en la sección 8
como contexto; **no lo implementes**.

## 2. Vocabulario

- **Base**: lo que trae siempre la shell.
- **Extensión**: cualquier pieza opcional. Hay dos tipos, con el mismo mecanismo de carga:
  - **Widget**: su única interfaz es una pieza visual que se coloca en un *hueco de widget*. Hoy el
    único hueco es el carrusel del dashboard; a futuro habrá otros (escritorio, paneles a medida),
    así que **un widget no debe saber dónde está colocado** ni asumir un tamaño fijo.
    Un widget **puede llevar un servicio en segundo plano** (estado, temporizadores,
    notificaciones). Ejemplo: Hidratación = widget + servicio de recordatorios.
  - **Complemento**: se integra en una o varias superficies de la shell (icono de estado en la
    barra, popout, pestaña del dashboard, página o sección de Nexus, anillo de recursos…) y puede
    llevar servicio y scripts. Un complemento puede además aportar widgets.

Regla para clasificar: si lo único que el usuario ve es la pieza del hueco (más notificaciones y sus
ajustes), es un widget. Si aparece en la barra, en un popout, en una pestaña, etc., es un complemento.

## 3. Clasificación de lo que hay hoy

| Pieza | Destino | Notas |
|---|---|---|
| Actividades, Updates, Bluetooth, Displays, Keybinds, retoques de UI | Base | Sin cambios |
| Bluetooth: selector de modo de audio (Música/Llamadas/Auto) | Base | Sirve para cualquier auricular |
| Bluetooth: batería de AirPods (L/estuche/R) | **Base durante la 0.2** | Candidata a complemento después (ver §8) |
| Portapapeles | **Base** | Hoy se configura en Complementos: mover sus ajustes fuera (fase 2) |
| Temporizadores | **Base** | Sigue teniendo interruptor on/off; sale de Complementos (fase 2) |
| Carrusel de widgets | Base | Es el hueco de widgets |
| Calendario | Widget **incluido en la base** | Para que el carrusel no quede vacío de serie |
| Hidratación | Widget (con servicio) | |
| Tareas | Widget (con servicio) | |
| Juegos (Steam) | Complemento | El más grande; migrar el último |
| VPN FortiClient (hoy «Madison VPN») | Complemento | Generalizar nombre y rutas (fase 1) |
| Batería del ratón Razer | Complemento | |

Mientras dure este plan las extensiones **siguen viviendo en este repo**, en su carpeta. Se
separarán en paquetes en el trabajo futuro.

## 4. Inventario actual (punto de partida)

Verifícalo con `git grep` antes de empezar; puede haber cambiado.

**Rutas personales** (2):
- `shell.qml:11` — pragma `QT_ADDITIONAL_PACKAGES_PREFIX_PATH=/home/manu/.local/lib/qt6/qml`
- `scripts/start-shell-with-tray-watcher.sh:8` — `SYLPH=/home/manu/.local/bin/sylph`

**VPN (Madison)**: `services/MadisonVpn.qml`, `modules/bar/popouts/{Vpn,VpnOtp,VpnSettings}.qml`,
`modules/bar/components/status/VpnStatus.qml`, referencias en `modules/bar/components/StatusIcons.qml`,
`modules/bar/popouts/Content.qml`, `modules/nexus/pages/ComplementsPage.qml`,
`modules/nexus/pages/panels/taskbar/BarStatusIcons.qml`, `shell.qml`, config `addons.madisonVpn`.
**Sus scripts no están en el repo**: viven en `~/.local/share/madison-vpn/` (`connect_vpn.sh`,
`disconnect_vpn.sh`, `heal_vpn.sh`, `status_vpn.sh`, `madison-vpn.helper`). Ojo: existe además
`services/VPN.qml`, que es el VPN genérico de upstream y **no** es esto.

**Hidratación**: `services/Hydration.qml`, `modules/dashboard/dash/HydrationWidget.qml`, shader
`plugin/src/Sylphrena/Shaders/water.frag`, ajustes en `modules/nexus/pages/panels/DashboardPanel.qml`,
registro en `services/DashWidgets.qml` y `modules/dashboard/dash/WidgetCarousel.qml`, arranque en
`shell.qml`, config `addons.hydration`, estado `~/.local/state/sylphrena/hydration.json`.

**Tareas**: `services/Tasks.qml`, `modules/dashboard/dash/TasksWidget.qml`, registro en
`DashWidgets`/`WidgetCarousel`, `dashboardTyping` en `components/ScreenState.qml`, config
`dashboard.tasksEnabled`, estado `tasks.json`.

**Juegos**: `services/Steam.qml` + `services/steam/*`, `modules/dashboard/GamesTab.qml` +
`modules/dashboard/games/*`, `components/images/SteamArt.qml`, `scripts/steam-activity.py`,
`scripts/steam-nonsteam.py`, pestaña en `modules/dashboard/Content.qml`, ajustes en
`ComplementsPage.qml`, arranque en `shell.qml`, config `addons.steam`, varios ficheros de estado
`steam-*.json` / `nonsteam-sessions.json`.

**Ratón Razer**: `services/RazerMouse.qml`, uso en `modules/dashboard/dash/Resources.qml`, fila en
`ComplementsPage.qml`, config `addons.razerMouse`, estado `razer-mouse.json`.

**Config compilada**: `plugin/src/Sylphrena/Config/addonsconfig.hpp` define `addons.*` en C++
(cambiarla exige recompilar e instalar el plugin). Las traducciones están en
`plugin/src/Sylphrena/I18n/trs/es.po` (también compiladas).

## 5. Diseño objetivo

### 5.1 Carpetas

```
extensions/
  hydration/        manifest.json, Service.qml, Widget.qml, Settings.qml, …
  tasks/
  games/
  vpn-forticlient/  (+ scripts/)
  razer-mouse/
```

Todo lo de una extensión (QML, scripts, shaders si es posible) vive en su carpeta. La base **no
importa** ningún fichero de `extensions/` por nombre.

### 5.2 Manifiesto

`manifest.json` por extensión. Campos mínimos:

```json
{
  "id": "hydration",
  "type": "widget",
  "name": "Hydration",
  "icon": "water_drop",
  "version": "0.1.0",
  "apiVersion": 1,
  "contributes": {
    "service": "Service.qml",
    "widgets": [{ "id": "hydration", "component": "Widget.qml" }],
    "settings": "Settings.qml"
  }
}
```

`contributes` de un complemento puede incluir además: `statusIcon`, `popouts`, `dashboardTab`,
`resourceRing`, `nexusSection`. **Define solo los puntos de enganche que necesiten las cinco
extensiones actuales**; no inventes otros. `apiVersion` existe para poder cambiar el contrato más
adelante sin romper extensiones instaladas.

Antes de fijar nombres, lee la rama `upstream/feat/plugins` (`plugin/src/Caelestia/Plugins/`,
`modules/nexus/pages/PluginsPage.qml`): upstream tiene un sistema de plugins a medias. No lo
adoptes (está parado y sin fusionar), pero **reutiliza sus nombres de campos y de puntos de
enganche donde encajen**, para abaratar una convergencia futura. Resume al usuario lo que
encuentres antes de decidir.

### 5.3 Carga (diseño validado el 2026-11-10)

El mecanismo ya está **probado en la shell real** y el código de partida está en el repo, sin
conectar. No lo rediseñes: complétalo.

**Código que ya existe**
- `services/Extensions.qml` — singleton cargador. Lanza `scripts/list-extensions.py` sobre los
  directorios de extensiones, compila los QML con `Qt.createComponent("file://…")`, crea el
  servicio de cada extensión y expone `loaded`, `widgets` y `service(id)`. Tiene un `IpcHandler`
  de depuración: `qs -c sylphrena ipc call extensions status`.
- `components/ExtensionSlot.qml` — coloca un componente aportado por una extensión, creándolo con
  `ext` y `service` ya asignados.
- `scripts/list-extensions.py` — devuelve los manifiestos en JSON (valida el `id`, el primero gana).
- `docs/examples/extension-spike/` — extensión de ejemplo con la forma exacta: `manifest.json`,
  `Service.qml`, `Widget.qml`, un fichero hermano y una subcarpeta.

(Histórico: en el spike nada referenciaba todavía a `Extensions`; la fase 3 lo conectó.)

**Contrato de una extensión**
- El **servicio no es un singleton**. Es un fichero cuya raíz es un `Scope` (de Quickshell) con
  `required property var ext`. La base crea **una** instancia y la guarda.
- Cada componente visual de la extensión declara `required property var ext` y
  `required property var service`, y los recibe al crearse. Dentro de la extensión todo se pasa
  por propiedades: `Hydration.drunkMl` pasa a ser `root.service.drunkMl`.
- `ext` es `{ id, dir, manifest, service }`. Los scripts propios se localizan con `ext.dir`.
- **La base nunca nombra una extensión** ni importa sus ficheros; solo recorre las listas de
  `Extensions`. Y una extensión nunca importa ficheros de otra.

**Lo que se comprobó que funciona** (y por tanto puedes dar por hecho)
- Cargar desde dentro del repo (`extensions/`) **y desde fuera** (`~/.local/share/sylphrena/extensions/`):
  en ambos casos los ficheros de la extensión pueden hacer `import qs.services`, `qs.components`,
  `qs.utils`, `Sylphrena.Config`, `Sylphrena.I18n` y usar `Colours`, `Tokens`, `Paths`,
  `GlobalConfig`, `Tr.tr`.
- Ficheros hermanos por nombre de tipo (`Sibling {}`) y subcarpetas con `import "parts"`.
- Un shader propio: la extensión incluye el `.qsb` ya compilado y lo usa con
  `fragmentShader: Qt.resolvedUrl("water.frag.qsb")`. Hay que distribuir el `.qsb`, no el `.frag`
  (se genera con `/usr/lib/qt6/bin/qsb`; el build del plugin lo deja en
  `build/plugin/src/Sylphrena/Shaders/.qsb/`). Así el shader de hidratación puede salir del plugin.
- El widget pintado en el carrusel con su servicio actualizándose en vivo.
- **Aislamiento de fallos**: una extensión con un error de sintaxis o un import inexistente deja
  un aviso claro en el log (`Extensions: <id>/<fichero>: <error>`), queda marcada con `error`, y ni
  la base ni las demás extensiones se ven afectadas.
- Con la carpeta `extensions/` borrada, la shell arranca sin errores.
- Coste en reposo del cargador: 0 % de CPU.

**Lo que NO se probó y te toca a ti en la fase 3**
- La **lista de extensiones activadas** (hoy carga todo lo que encuentra) y activar o desactivar
  en caliente: al desactivar hay que destruir el servicio (`destroy()`) y quitar sus aportaciones.
- La **config por extensión** (§5.4).
- Los demás puntos de enganche (`statusIcon`, `popouts`, `dashboardTab`, `resourceRing`,
  `nexusSection`): sigue el mismo patrón que `widgets` (lista plana en `Extensions` +
  `ExtensionSlot` en la superficie de la base).
- Extensiones grandes con mucho estado compartido (Juegos): el servicio único pasado por
  propiedades debería bastar, pero no está probado a esa escala.
- Añadir o quitar una carpeta con la shell en marcha (hoy solo se lee al arrancar; basta con eso).

**Trampas encontradas**
- `Loader.sourceComponent` no permite pasar propiedades `required`: por eso existe
  `ExtensionSlot`, que usa `component.createObject(padre, { ext, service })`.
- `Qt.createComponent` devuelve el error en `errorString()` cuando `status !== Component.Ready`;
  compruébalo siempre antes de crear.
- El nombre de fichero que viene del manifiesto es entrada externa: `Extensions.component()` ya
  rechaza rutas con `..` o caracteres raros. Mantén esa validación en todo lo que venga del manifiesto.

### 5.4 Configuración y traducciones

- Cada extensión guarda su configuración en `~/.config/sylphrena/extensions/<id>.json`, leída y
  escrita desde QML (patrón `FileView` ya usado en `services/Tasks.qml`). Deja de depender de
  `addons.*` en C++. La base solo guarda **qué extensiones están activadas** y el orden de widgets.
- Migración: al primer arranque con el sistema nuevo, copiar los valores existentes de `addons.*`
  y `dashboard.tasksEnabled` al fichero nuevo. El usuario no debe perder su configuración.
- El estado (`~/.local/state/sylphrena/*.json`) no cambia de sitio en este plan.
- Traducciones: hoy son un `.po` compilado en el plugin. Para este plan, **las cadenas de las
  extensiones se quedan en el `es.po` común**. Sacarlas es trabajo futuro; anótalo, no lo resuelvas.

## 6. Fases

Cada fase es una rama + PR propia contra `dev/0.2` (flujo de AGENTS.md §3, cambiando la base de la PR). No empieces una fase sin que la
anterior esté fusionada y el usuario haya probado la shell. Al final de cada fase: shell
reiniciada, log sin errores nuevos, `AGENTS.md`/`FEATURES.md`/`CONFIG.md`/`CHANGELOG.md` al día.

### Red de seguridad (ya preparada el 2026-11-10)

- **Código**: `main` no se toca y está en GitHub. Volver a la versión estable = `git checkout main`
  y reiniciar la shell.
- **Datos del usuario** (lo que git no cubre): copia en
  `~/Backups/sylphrena-pre-0.2-2026-11-10/` de `~/.config/sylphrena`, `~/.local/state/sylphrena` y
  `~/.local/share/madison-vpn`, con un `LEEME.txt` que explica cómo restaurar. Contiene datos
  privados (clave de Steam, scripts de la VPN): **nunca la subas ni la copies al repo**.
- **Sistema**: el usuario tiene Timeshift (Btrfs). Ojo: su restauración no incluye `/home` por
  defecto, así que no devuelve la shell; para eso están las dos anteriores.
- Antes de cualquier fase que migre configuración o estado (fases 1, 3, 4), comprueba que esa
  copia sigue existiendo. Si una migración sale mal, restaura desde ahí en lugar de reconstruir a mano.
- **No borres esta copia durante el plan.** Se borra solo al final (ver fase 5).

### Fase 0 — Línea base
- Anota el estado de partida: log de arranque limpio, memoria y CPU en reposo (cómo medir: AGENTS.md §6).
- **Hecho cuando**: tienes esas cifras apuntadas en la descripción de la PR de la fase 1.

### Fase 1 — Quitar lo personal
- Sustituir las dos rutas `/home/manu`. El pragma de `shell.qml` no admite variables: investiga
  cómo resolverlo (generar el valor en el arranque desde `sylph`/el script, o instalar el plugin
  donde Qt lo encuentre sin pragma) y propón la opción al usuario antes de implementarla.
- Renombrar Madison VPN → **VPN FortiClient**: servicio, popouts, textos, id de config
  (`addons.madisonVpn` → nombre nuevo, con migración del valor), y directorio de scripts.
- Traer los scripts de `~/.local/share/madison-vpn/` al repo **solo tras revisarlos con el
  usuario**: pueden contener host, usuario o rutas del trabajo. Nada de credenciales ni datos de
  empresa en el repo (AGENTS.md §2). La configuración de host/puerto/usuario ya es editable desde
  el popout de ajustes.
- **Hecho cuando**: `git grep -i "madison\|/home/manu"` solo devuelve documentación histórica, y la
  VPN conecta igual que antes en el equipo del usuario (lo prueba él).

### Fase 2 — Portapapeles y Temporizadores a la base
- Sacar sus filas de `ComplementsPage.qml` y colocar sus ajustes donde corresponda en Nexus
  (propón el sitio al usuario; Temporizadores ya tiene ajustes en `Panels → Taskbar → Clock`).
- Temporizadores conserva su interruptor on/off.
- **Hecho cuando**: Complementos ya no los lista y ambos funcionan igual.

### Fase 3 — Armazón de extensiones + primera migración (Tareas)
- La prueba de carga dinámica **ya está hecha** (§5.3). Parte del código existente.
- Conectar `Extensions` (referenciarlo en `shell.qml`), y completar: lista de extensiones
  activadas, config por extensión y el punto de enganche `widgets` en el carrusel.
- Migrar **Tareas** (la más simple: servicio + widget, sin shader ni notificaciones). El
  calendario pasa a ser un widget incluido en la base usando el mismo punto de enganche.
- Sustituir la sección «Carrusel de widgets» de Nexus para que liste lo que haya, sin nombres fijos.
- **Hecho cuando**: con `extensions/tasks/` borrada la shell arranca sin errores y el carrusel
  muestra solo el calendario; restaurada, Tareas funciona como antes y conserva sus tareas.

### Fase 4 — Migrar el resto, de menor a mayor
Orden: **Hidratación** (añade servicio con notificaciones y shader) → **Ratón Razer** (añade
`resourceRing`) → **VPN FortiClient** (añade `statusIcon`, `popouts`, scripts) → **Juegos**
(añade `dashboardTab`; es grande, puede ir en varias PRs).
- Una PR por extensión. En cada una: mover ficheros, definir el punto de enganche nuevo si hace
  falta, migrar su config fuera de C++, y repetir la prueba de borrar su carpeta.
- La página Complementos de Nexus pasa a listar las extensiones de tipo complemento que existan,
  con su interruptor y su `Settings.qml`.
- **Hecho cuando**: con `extensions/` vacía la shell arranca limpia y completa en lo que es base;
  con todo presente, cada extensión se comporta igual que antes de la migración.

### Fase 5 — Limpieza
- Eliminar `addons.*` de `addonsconfig.hpp` (solo lo ya migrado) y recompilar el plugin.
- Repetir las mediciones de la fase 0: no debe haber regresión de memoria ni de CPU en reposo.
- Documentar en `AGENTS.md` y `FEATURES.md` cómo es una extensión y cómo se añade una.
- **Borrar la copia de seguridad** `~/Backups/sylphrena-pre-0.2-2026-11-10/` — solo cuando se
  cumplan las tres condiciones: `dev/0.2` fusionada en `main`, tag `v0.2.0` creado, y el usuario
  ha usado la 0.2.0 con normalidad y **confirma expresamente** que se puede borrar. Pregúntaselo;
  no la borres por tu cuenta. Quita entonces también este apartado de red de seguridad del plan.

## 7. Reglas de trabajo (además de AGENTS.md)

- **Un complemento no modifica la base.** «Más alcance» que un widget significa engancharse en más
  sitios previstos, no parchear ficheros de la base. Si una extensión necesita algo que no existe,
  se añade un punto de enganche a la base.
- **No cambies el comportamiento visible.** Esto es una reorganización: tras cada fase el usuario
  debe ver exactamente lo mismo. Las mejoras van aparte.
- **Reinicia la shell vía Hyprland** (`hyprctl dispatch 'hl.dsp.exec_cmd("/home/manu/.local/bin/sylph shell -r -d")'`),
  nunca desde tu propio terminal: hereda `no_new_privs` y rompe `sudo` dentro de la shell.
- La recarga en caliente de QML no siempre aplica: reinicia antes de sacar conclusiones.
- No pruebes con el ratón o el teclado del usuario sin avisar, ni reinicies la shell mientras juega.
- No toques `~/.config/sylphrena/shell.json` del usuario sin copia y sin restaurarlo.
- Commits locales, sin trailers ni pies de agente; push y fusión solo cuando el usuario lo diga.
- Di siempre qué has verificado y qué no (no puedes hacer clic: dilo y pide al usuario que pruebe).
- Si una fase se complica más de lo previsto, para y explica el problema; no la fuerces.

## 8. Fuera de alcance (trabajo futuro, solo contexto)

- **Paquetes AUR**: `sylphrena-shell`, `sylphrena-cli`, y paquetes para Seeker y Things. Seeker y
  Things son **dependencias opcionales**, nunca obligatorias.
- **Asistente de primer arranque** en la shell (pacman no permite pasos interactivos al instalar):
  sugiere instalar Seeker, Things y extensiones.
- **Extensiones como paquetes** (`sylphrena-widget-*`, `sylphrena-addon-*`) en un directorio de
  sistema, más un directorio de usuario para instalar desde una carpeta local.
- **Sección en Things** que aparece si detecta Sylphrena y lista las extensiones por pestañas.
- **Más huecos de widgets** (escritorio, paneles a medida y redimensionables).
- **Extensiones de terceros** y guía para crearlas (implica pensar la seguridad: una extensión es
  código que corre con los permisos del usuario).
- **Otras distribuciones** además de Arch.
- **Traducciones por extensión.**
- **Batería de AirPods como complemento.** Es específica de un dispositivo (canal propietario de
  Apple, `scripts/airpods-battery.py`, `services/BluetoothAudio.qml`, `components/bluetooth/*`), así
  que por coherencia debería ser un complemento, igual que el ratón Razer. Se queda en la base en
  la 0.2 porque no molesta a quien no tiene AirPods (sin interruptor ni ajustes; solo se activa al
  conectarlos) y sacarla exige un punto de enganche nuevo en el popout de Bluetooth: un
  **«proveedor de batería por dispositivo»**. Ese enganche serviría también a otros dispositivos
  (teclado, ratón), por lo que merece diseñarse aparte. **No lo toques en este plan.**
- **Temas y efectos** (cambian el aspecto global): serían un tercer tipo de extensión, con reglas propias.
- **Dónde se alojan las extensiones**: un único repo `sylphrena-extensions` con una carpeta por
  extensión y un índice (`index.json`) que Things lee; cada extensión se publica además como
  paquete. Por eso en este plan viven en `extensions/` con esa misma forma de carpeta.

Tenlo presente al diseñar (por eso existen `apiVersion`, el manifiesto y los widgets que no
conocen su hueco), pero no construyas nada de esta lista.
