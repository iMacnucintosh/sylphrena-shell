# Registro de ejecución del plan modular

Diario de lo hecho fase a fase (ver [PLAN-MODULAR.md](./PLAN-MODULAR.md)). Aquí van las **decisiones
tomadas sin consultar al usuario** y lo que queda pendiente de que las revise.

## Fase 0 — Línea base (2026-11-10)
Shell recién reiniciada, `dev/0.2` en `3c842ca7`: RSS 360 MB (anónima 180 MB, páginas enormes
desactivadas), CPU en reposo 0 % (0 ticks en 10 s), log de arranque limpio (solo los avisos
conocidos `Config.border…` y `powerprofiles`). Copia de datos de usuario verificada.

## Fase 1 — Quitar lo personal (2026-11-10)
Hecho. Rama `feature/phase-1-personal`, fusionada en `dev/0.2`.

- **`shell.qml` sin ruta de usuario.** `pragma Env` no expande `$HOME` (comprobado: el valor llega
  literal), así que no puede ser genérico. Decisión: lo exporta el lanzador. `sylph shell`
  (repo `sylphrena-cli`, commit `588ce79`, **solo local**) añade `QT_ADDITIONAL_PACKAGES_PREFIX_PATH`
  si existe `~/.local/lib/qt6/qml/Sylphrena`. Verificado tras reiniciar: la shell carga los
  plugins de `~/.local/lib/qt6/qml` y el log sale limpio.
  - ⚠️ Ese commit está en la rama `feature/rebrand-sylphrena` del CLI, junto a otro anterior (THP)
    y a tus cambios sin commitear (`record.py`, `notify.py`, `i18n.py`), que no he tocado. Hasta
    que no lo subas, la shell de **otro** equipo que use el CLI original no cargaría un plugin local.
- **`start-shell-with-tray-watcher.sh`**: `sylph` se resuelve con `command -v` y cae a `$HOME/.local/bin/sylph`.
- **Madison VPN → VPN FortiClient.** Servicio `FortiVpn`, config `addons.fortiVpn` (clase C++
  `AddonsFortiVpn`), textos y traducciones. La config antigua se migra sola
  (`scripts/migrate-config.py` + `services/ConfigMigration.qml`; probado con tu `shell.json` real:
  `addons.madisonVpn` → `addons.fortiVpn`, valor conservado).
- **Scripts de la VPN NO traídos al repo.** Los revisé: contienen IPs de DNS e intranet, el host de
  la intranet de la empresa, tu usuario y `/home/manu`, y dependen de un ayudante con privilegios
  en `/usr/local/sbin`. El plan decía traerlos solo tras revisarlos contigo; como no estabas, los
  dejé fuera. La shell los busca ahora en `~/.local/share/sylphrena/vpn-forticlient/`; creé en tu
  home un **enlace simbólico** a `~/.local/share/madison-vpn` (tus ficheros no se han movido).
  El contrato de los scripts está documentado en `FEATURES.md`.
- `git grep -i "madison\|/home/manu"` solo devuelve la tabla de migración, el historial del
  CHANGELOG, `AGENTS.md`/`FEATURES.md` (notas de migración) y este plan.

## Fase 2 — Portapapeles y Temporizadores a la base (2026-11-10)
Hecho. Rama `feature/phase-2-base`, fusionada en `dev/0.2`.

- **Temporizadores**: se quitó su fila de Complementos. Su interruptor on/off y los presets ya
  estaban en `Panels → Taskbar → Clock` (mismo `addons.timers.enabled`), así que no hizo falta mover nada más.
- **Portapapeles**: se quitó su tarjeta de Complementos y sus ajustes (interruptor + tamaño del
  historial) pasan a una sección **Portapapeles** al final de `Panels → Utilities`. **Decisión
  mía** (el plan pedía proponer sitio al usuario): `utilities.clipboard` ya es esa rama de config.
  Se conserva el `Clipboard.ensureWatchers()` al activar.
- Verificado con la shell real (capturas): Complementos lista VPN FortiClient, Batería del ratón
  Razer y Juegos; Utilidades muestra Portapapeles con interruptor y tamaño de historial.
- Textos/traducciones actualizados (descripción de la página Complementos).

## Fase 3 — Armazón de extensiones + Tareas (2026-11-10)
Hecho. Rama `feature/phase-3-extensions`, fusionada en `dev/0.2`.

- **Conectado el cargador** (`services/Extensions.qml`, en `shell.qml`): descubre manifiestos,
  crea el servicio de las extensiones activadas y lo destruye al desactivarlas, en caliente.
  Lista de activadas en config `extensions.enabled` (nuevo nodo C++ `ExtensionsConfig`; nada
  activado por defecto).
- **Config por extensión** (`components/ExtensionConfig.qml`, `ext.config.get/set`):
  `~/.config/sylphrena/extensions/<id>.json`. Probado: se guarda y sobrevive a un reinicio.
- **Punto de enganche `widgets`**: `DashWidgets` ahora mezcla widgets propios de la base
  (calendario; Hidratación hasta la fase 4) y los declarados por extensiones (por manifiesto, aunque
  estén desactivadas, para poder listarlas en Nexus). El carrusel coloca los de extensiones con
  `ExtensionSlot` y les pasa `screenState`.
- **Tareas migrada** a `extensions/tasks/` (manifest + Service + Widget). `services/Tasks.qml` y
  `TasksWidget.qml` ya no existen. Su estado (`tasks.json`) no se tocó: la tarea existente del
  usuario se conserva.
- **Migración de config**: `dashboard.tasksEnabled` → `extensions.enabled += ["tasks"]`
  (`scripts/migrate-config.py`, probado con el `shell.json` real). El nodo C++ antiguo se
  eliminó (un aviso `Unknown option` la primera vez, inofensivo).
- **Verificado**: (1) con `extensions/` borrada la shell arranca limpia y el carrusel queda vacío
  (para este usuario el calendario está desactivado) con el botón «Activa widgets»; (2) restaurada,
  Tareas funciona y conserva sus datos; (3) activar/desactivar en caliente destruye y recrea el
  servicio y deja `extensions.enabled` bien; (4) la sección «Carrusel de widgets» de Nexus lista
  Tareas traducida (sale del manifiesto).
- **Incidente**: tras añadir el nodo C++ olvidé añadir `extensionsconfig.hpp` al `CMakeLists.txt`
  del módulo: el plugin compilaba pero la shell no arrancaba (`undefined symbol`). Estuvo caída
  ~3 min hasta corregirlo. Anotado en AGENTS.md.
- No probado: instalar una extensión desde `~/.local/share/sylphrena/extensions/` con la shell
  ya en marcha (hoy solo se descubre al arrancar; basta con reiniciar).

## Fase 4 — Hidratación (2026-11-10)
Hecho. Rama `feature/phase-4-hydration`, fusionada en `dev/0.2`.

- **Hidratación migrada** a `extensions/hydration/` (manifest, `Service.qml`, `Widget.qml`,
  `Settings.qml`, `water.frag` + `water.frag.qsb`). `services/Hydration.qml`, `HydrationWidget.qml`
  y el shader del plugin ya no existen; `AddonsHydration` salió del C++.
- **Punto de enganche nuevo: ajustes de extensión en Nexus.** Una extensión puede aportar
  `contributes.settings`; la tarjeta del carrusel en `DashboardPanel` ya no sabe nada de
  Hidratación: carga ese componente con `ExtensionSlot`, muestra `service.summary` y el
  `offNote` del manifiesto cuando está apagada. La fila de ajustes se extrajo a
  `modules/nexus/common/SpinSettingRow.qml` (reutilizable por extensiones).
- **Config**: los valores de `addons.hydration.*` pasan a `~/.config/sylphrena/extensions/hydration.json`
  y `addons.hydration.enabled` a `extensions.enabled` (`scripts/migrate-config.py`, probado con el
  `shell.json` real: meta 2600 conservada). El orden por defecto del carrusel ya no nombra extensiones.
- **Shader**: distribuido compilado (`qsb --glsl "300es,330" -b -O`), cargado con `Qt.resolvedUrl`.
  Comprobado que el agua se mueve.
- **Verificado en la shell real**: widget con el estado previo (997/2600 ml), recordatorio
  (notificación con botones 20/83 ml) disparado a mano, tarjeta de ajustes de Nexus con los
  valores migrados.
- Acoplamiento cosmético que queda: `utils/Icons.qml` mapea por texto las notificaciones de agua a
  un icono. No es una dependencia de código; se puede mover a la extensión si se quiere.
- ⚠️ Mi salida de un comando mostró en el terminal la clave de la API de Steam de tu `shell.json`
  (no se ha guardado en ningún fichero ni commit). Si te preocupa, regénerala.

## Fase 4 — Ratón Razer (2026-11-10)
Hecho. Rama `feature/phase-4-razer`, fusionada en `dev/0.2`.

- `extensions/razer-mouse/` (tipo `addon`). `services/RazerMouse.qml` y `AddonsRazerMouse` (C++) ya no existen.
- **Enganche nuevo `resourceRing`**: el servicio expone `ring { shown, value, icon, warn, badge }` y
  `dash/Resources.qml` ya no nombra el ratón: usa `Extensions.resourceRing` para sustituir el
  anillo de almacenamiento.
- **Página Complementos genérica**: `modules/nexus/common/ExtensionCard.qml` lista las extensiones
  de tipo `addon` (icono, `statusText`, interruptor, `Settings.qml` desplegable). Verificado: la
  fila del ratón («Basilisk V4 Pro · 33 %») sale del manifiesto y del servicio.
- Config migrada (`addons.razerMouse.*` → `extensions.enabled` + `extensions/razer-mouse.json`).
  Anillo verificado en el dashboard (33 %).
- Lección: `ExtensionCard` no importaba `Sylphrena.Config` (`Tokens` sin definir → altura 0 y filas
  solapadas). Los `ReferenceError` de QML solo salen en el log: mirarlo siempre.
