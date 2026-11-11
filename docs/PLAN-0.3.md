# Plan 0.3: Things como gestor de extensiones y widgets

Documento de trabajo. Léelo junto con [AGENTS.md](../AGENTS.md). Si algo choca con el código,
**para y pregunta al usuario**; no improvises un rediseño.

Estado: **fase 0 y fase B (base) hechas (2026-11-11)**; fase 1 (Things) por empezar. La 0.2.0 está publicada (`v0.2.0`, PR #34). La rama de trabajo
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

### Fase 0 · Decisiones y contrato — HECHA (2026-11-11)
Decisiones del usuario:
- **Confianza:** `sha256` + confirmación al instalar; **índice sin firmar** por ahora (revisable más adelante).
- **Extensiones de serie (Tareas, Hidratación, Juegos): pasan TODAS al hub.** La shell se queda sin extensiones propias. Ver fase 4 para el orden y los riesgos.
- **Alcance del catálogo:** solo extensiones y widgets (`kind` en el índice; temas y fondos fuera de la 0.3).
- **Extensiones instaladas a mano:** se muestran como «local» y se respetan.

Entregado:
- Contrato escrito en `AGENTS.md` («Contrato con Things»): carpeta, manifiesto (`apiVersion`, `requires.sylphrena`), recibo `.source.json`, orden de instalar/eliminar, IPC y confianza.
- Shell: comprobación de `apiVersion` / `requires` al cargar (incompatible = listada, no cargada, con motivo), recibo de origen en `list-extensions.py`, y IPC `extensions list | rescan | enable | disable | prepareRemoval`.
- `scripts/ext.py` (instalar / quitar / listar / activar desde terminal; `sylph ext` lo llamará: el CLI vive en otro repo, aún sin tocar).
- Corregido de paso: el plugin instalado decía `0.1.0` (caché de CMake con `-DVERSION`); ahora toma el último tag.
- Pendiente de la fase 0 en el **hub** (se hace en la fase 4): que `build.py` copie `requires` / `apiVersion` del manifiesto al `index.json` y los valide.

### Fase B · Cerrar la base: asistente de bienvenida y enlace a Things — HECHA (2026-11-11)
Orden decidido por el usuario: antes de centrarse en Things, dejar bien cerrado el sistema base.
Decisiones:
- **Ventana propia**, flotante y de tamaño fijo (960×720), de 4 pasos; sale sola la primera vez y se reabre con un botón de varita en la tarjeta de Sylphrena de Nexus → Acerca de. El orbe vuela del centro al lado del título.
- **Visual:** el orbe y tarjetas Material You; **capturas reales a futuro**. Invita a crear extensiones propias (enlace al hub).
- **Autoría:** alias de GitHub (`iMacnucintosh`) con enlace + crédito a `caelestia-shell` (soramane). Sin nombre real ni correo.
- **El asistente es solo informativo con las apps** (Seeker, Things, kitty): **las instala el paquete base** (fase 3), no el asistente. (Se descartó instalar desde el asistente con `makepkg`: añadía contraseña, compilación y fallos posibles.)
- **Sin extensiones de serie:** Nexus → Extensiones lleva la fila «Buscar más en Things» (abre Things; desactivada con aviso si no está instalado).

Entregado: `services/Companions.qml`, `services/Welcome.qml`, `modules/welcome/WelcomeWindow.qml`, botón en Acerca de, fila de Things en Extensiones.

### Fase 1 · Things lee el hub
Decisiones (2026-11-11): **sección propia «Sylphrena»** en la columna lateral de Things (no un filtro más junto a pacman/AUR/Flatpak) y **la lógica de instalar vive en la shell** (`scripts/ext.py install-hub …`), Things solo la llama (como un comando más de su cola `Operations`, con su `askpass`).
Hecho en la shell: `ext.py install-hub`, `list --json`, `info`, `sudo -A` con `SUDO_ASKPASS`, y `inspect` con `requires`/`apiVersion`. Pendiente: el índice del hub con `requires`/`apiVersion`/`system`, y todo lo de Things (`HubCatalog` en C++, fuente `sylphrena` en `Operations`, vista QML, localizar `ext.py`).
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
- **El paquete base depende de Things, Seeker y kitty** (decidido): Things y Seeker necesitan su `PKGBUILD` (Seeker ya lo tiene en la rama local `feature/pkgbuild` de su repo, sin fusionar; Things falta); kitty es de los repos oficiales. Siguen siendo opcionales en el código (la shell funciona sin ellos).
- **Conectar kitty:** ser dueña de kitty significa que la base debe dejarlo integrado, no solo instalado: en el primer arranque, añadir a `~/.config/kitty/kitty.conf` (solo si faltan, con copia) el `include` del tema, `allow_remote_control yes` y `listen_on …`, y crear la plantilla y el script de recarga (hoy se hace a mano, ver FEATURES «Kitty y colores»).
- Dependencias duras del paquete (no sugerencias): `qt6ct`, `cliphist`, `wl-clipboard`, `wtype`, fuentes; recomendadas: Papirus y `adw-gtk-theme`.
- `scripts/install-system.sh` y el instalador de Things se coordinan (un solo sitio que instale lo de root).

### Fase 4 · El hub crece (y la shell se queda sin extensiones propias)
- `scripts/build.py --check` en CI del hub; `requires` y `apiVersion` copiados del manifiesto al índice y validados.
- **Migrar al hub Tareas, Hidratación y Juegos.** Orden: publicarlas en el hub **antes** de quitarlas de `extensions/` de la shell, y quitarlas solo cuando Things pueda instalarlas (fase 1). Antes de cada una:
  - comprobar de qué depende del plugin y de `qs.*` (Hidratación lleva un shader; Juegos scripts Python y varias capas) y que funcione desde `~/.local/share/sylphrena/extensions/`;
  - su `i18n/es.json` (`scripts/extension-catalog.py`): hoy sus cadenas viven en el `es.po` de la shell y dejarían de estar;
  - sus ajustes y su estado (`~/.config/sylphrena/extensions/<id>.json`, `~/.local/state/sylphrena/…`) **no se tocan**: los ids no cambian, así que el usuario que ya las usa no pierde datos;
  - el usuario actual (Manu) las reinstala desde Things o con `scripts/ext.py install`.
- La shell sigue aceptando una carpeta `extensions/` propia (para desarrollar), aunque vacía.
- Añadir widgets al hub y documentar cómo publicar (ya está en el README del hub).

## 4. Preguntas abiertas
- ~~Primer arranque sin extensiones~~ (respondida: la página Extensiones lleva un enlace a Things; el asistente de bienvenida presenta la shell).
- **Firma del índice** (decidido no hacerla ahora): ¿en qué versión se revisa?
- **Qué pasa con una extensión del hub que se quita del catálogo** (retirada): ¿Things avisa en «instaladas» o la ignora?

## 5. Pendiente heredado de la 0.2
- Tests pytest ligeros (parser VDF, merge de sesiones Millennium, residual delta/sesión).
- Heatmap de Steam vacío: rellenar cifras del mes con logros cuando no hay tiempo.
- Backups, contraseña de `sudo` y clave de Steam: cambios del lado del usuario (ver AGENTS.md).
