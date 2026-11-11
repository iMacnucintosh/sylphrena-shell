# Plan 0.3: Things como gestor de extensiones y widgets

Documento de trabajo. Léelo junto con [AGENTS.md](../AGENTS.md). Si algo choca con el código,
**para y pregunta al usuario**; no improvises un rediseño.

Estado: **por empezar** (2026-11-11). La 0.2.0 está publicada (`v0.2.0`, PR #34). La rama de trabajo
es `dev/0.3` y sigue el mismo flujo: cada fase en una rama `feature/*` que sale de `dev/0.3` y se
fusiona en ella; `main` no se toca hasta cerrar la 0.3 (PR `dev/0.3` → `main` y tag `v0.3.0`).

---

## 1. Objetivo

Que **Things** (`~/Desarrollo/things`, gestor de paquetes Material You) sea un paquete **base y requerido**
de Sylphrena y gestione el **catálogo, la instalación, la actualización y la eliminación** de
extensiones y widgets, leyendo el catálogo del hub público
([`sylphrena-hub`](https://github.com/iMacnucintosh/sylphrena-hub), `index.json`).

Reparto de responsabilidades (decidido):

| | Things | Sylphrena (shell / Nexus) |
| --- | --- | --- |
| Descubrir, descargar, comprobar `sha256` | sí | no |
| Instalar / actualizar / eliminar ficheros | sí | no (solo vía CLI de emergencia) |
| Piezas con root (`system/*.sh`), contraseña | sí | no |
| Cargar, activar y desactivar (`extensions.enabled`) | no | **sí** (estado en vivo) |
| Ajustes de cada extensión | no | **sí** (tarjeta / páginas propias) |

El contrato entre las dos aplicaciones es **la carpeta `~/.local/share/sylphrena/extensions/<id>/`
más el `manifest.json`**, y un aviso a la shell para que vuelva a escanear
(`qs -c sylphrena ipc call extensions rescan`, por añadir).

Nexus **conserva una página «Extensiones» pequeña**: lista de las instaladas con su interruptor y
sus ajustes, y un botón «Buscar más en Things». Desaparece de ella: instalar desde zip, la petición
de contraseña y la gestión de piezas de sistema.

## 2. Principios

- **Requerido en el paquete, opcional en el código:** la shell no falla ni pierde extensiones si
  Things no está. Lo ya instalado sigue cargando. Hay una vía mínima por línea de comandos
  (`sylph ext install <zip>`, basada en `scripts/install-extension.py`) para no quedarse sin
  instalar nada si Things se rompe.
- **Confianza:** el catálogo es público y las extensiones pueden ejecutar scripts como root. Things
  comprueba `sha256` del índice, muestra siempre qué se va a instalar (nombre, versión, si pide
  root) y pide confirmación. A medio plazo, índice firmado.
- **Compatibilidad:** cada extensión declara con qué versión de Sylphrena funciona
  (`requires` en el manifiesto) y Things lo comprueba antes de instalar.
- **i18n siempre** (regla de AGENTS.md §3), también en Things y en el catálogo: textos con `Tr`, sin
  cadenas sin traducir.
- **Nada privado** en el hub ni en Things.

## 3. Fases

### Fase 0 · Decisiones y contrato
- Definir `requires` (p. ej. `{ "sylphrena": ">=0.3.0" }`) y `apiVersion` en el manifiesto y en `index.json`.
- Decidir el modelo de confianza (sha256 + confirmación; ¿firma del índice ya o después?).
- Decidir qué extensiones de serie siguen **dentro** de la shell (`extensions/`) y cuáles pasan al hub
  (hoy: Tareas, Hidratación, batería Razer, Juegos viven en el repo de la shell).
- Añadir a la shell el comando IPC `extensions rescan` (hoy solo existe `status`) y `sylph ext install/remove/list`.
- Entregable: este documento actualizado y el contrato escrito en AGENTS.md.

### Fase 1 · Things lee el hub
- Pestaña «Sylphrena» en Things (junto a pacman/AUR/Flatpak): lista del `index.json` (extensiones y,
  cuando haya, widgets), con descripción, versión, estado (instalada / actualizable) e icono.
- Instalar / actualizar / quitar: lógica de `scripts/install-extension.py` (validación del zip: sin
  rutas absolutas ni `..`, sin enlaces, límites de tamaño, id válido) y `sha256` del índice.
- Piezas de sistema (`system.install/uninstall/check`): Things ejecuta esos scripts con su flujo de
  contraseña (en RAM, `sudo -S -k`, nunca a fichero ni argv).
- Caché del índice con TTL y funcionamiento sin conexión con los últimos datos.
- Tras instalar, activar la extensión (la shell lo hace al detectarla; ver fase 2) y avisar con `rescan`.

### Fase 2 · La shell se adelgaza
- Nexus → Extensiones: instaladas + interruptor + ajustes + «Buscar más en Things». Se retiran de la
  shell: instalar desde zip, tarjeta de contraseña, `runSystem`, `zipPending`, `install-extension.py` (queda en la CLI).
- La regla «instalar activa la extensión» pasa a Things (o a la shell al ver una carpeta nueva marcada como recién instalada).
- Actualizar la documentación (AGENTS.md, FEATURES.md, CHANGELOG.md) y las cadenas (i18n).

### Fase 3 · Empaquetado
- Things como dependencia del paquete de Sylphrena (AUR); sigue siendo opcional en el código.
- `scripts/install-system.sh` y el instalador de Things se coordinan (un solo sitio que instale lo de root).

### Fase 4 · El hub crece
- `scripts/build.py --check` en CI del hub; `requires` validado.
- Migrar al hub las extensiones de serie que se decida (fase 0) y añadir widgets.
- Documentar cómo publicar (ya está en el README del hub).

## 4. Preguntas abiertas
- ¿Firma del índice en la 0.3 o más adelante?
- ¿Se quedan Tareas / Hidratación / Juegos / batería Razer en el repo de la shell o pasan al hub?
- ¿Things instala también temas, fondos y esquemas del hub (más allá de extensiones y widgets)?
- ¿Qué pasa con las extensiones instaladas a mano en `~/.local/share/sylphrena/extensions/` sin pasar por el catálogo (se muestran como «local»)?

## 5. Pendiente heredado de la 0.2
- Tests pytest ligeros (parser VDF, merge de sesiones Millennium, residual delta/sesión).
- Heatmap de Steam vacío: rellenar cifras del mes con logros cuando no hay tiempo.
- Backups, contraseña de `sudo` y clave de Steam: cambios del lado del usuario (ver AGENTS.md).
