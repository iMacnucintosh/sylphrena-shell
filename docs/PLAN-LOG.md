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
