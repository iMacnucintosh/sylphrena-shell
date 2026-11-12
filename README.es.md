<h1 align="center">Sylphrena</h1>

<p align="center"><a href="./README.md">English</a> · <strong>Español</strong></p>

<p align="center">
Un escritorio <strong>Material You</strong> completo para <a href="https://hypr.land">Hyprland</a>: barra, paneles, actividades, ajustes, pantalla de inicio de sesión y apps propias, todo con el mismo aspecto y en español.
</p>

<div align="center">

![Última versión](https://img.shields.io/github/v/tag/iMacnucintosh/sylphrena-shell?filter=v0.*&style=for-the-badge&labelColor=101418&color=9ccbfb&label=versi%C3%B3n)
![Último commit](https://img.shields.io/github/last-commit/iMacnucintosh/sylphrena-shell?style=for-the-badge&labelColor=101418&color=b9c8da&label=%C3%BAltimo%20cambio)

</div>

https://github.com/user-attachments/assets/1d005d8f-ab43-442d-a75a-917899f02845

## Instalación

Necesitas **Arch Linux**. Desde una terminal, con tu usuario (no como root):

```sh
git clone https://github.com/iMacnucintosh/sylphrena-shell
cd sylphrena-shell
./install.sh
```

El instalador mira qué tiene tu sistema, te enseña qué va a instalar y por qué, y **no toca nada hasta que confirmas**. Pide la contraseña una sola vez, e instala también Hyprland si aún no lo tienes. Al terminar, cierra sesión (o reinicia): entrarás por la pantalla de inicio de sesión de Sylphrena y, la primera vez, te recibirá un asistente de bienvenida con lo básico.

Puedes repetirlo cuando quieras: solo hace lo que falte. Para ver qué haría sin cambiar nada, `./install.sh --dry-run`.

Compila algunos paquetes, así que tómatelo con calma; en un equipo con poca memoria (una máquina virtual de 2 GB, por ejemplo) compila de uno en uno y tarda más.

<!-- captura: docs/media/installer.webp — el instalador con la lista de pasos -->

## Qué trae

### Actividades

Agrupa tus escritorios por contexto (por ejemplo *Principal*, *Juegos* y *Trabajo*). Cada actividad tiene **su propio fondo, esquema de colores y modo claro u oscuro**, y al cambiar de una a otra todo el sistema cambia de aspecto. Puedes **anclar apps** a un escritorio para que siempre se abran allí, y con `Super+Tab` ves todas las actividades a la vez y arrastras ventanas entre ellas.

Las transiciones también se eligen: por defecto, deslizar en vertical entre escritorios y un fundido al cambiar de actividad.

<!-- captura: docs/media/activities.webp — vista general (Super+Tab) -->

### Barra y paneles

Una barra lateral con tus escritorios y los iconos de sus apps, la bandeja del sistema, el reloj y los indicadores. Los paneles salen de la propia barra:

- **Dashboard** con el tiempo, multimedia, rendimiento del equipo y un carrusel de widgets (calendario y los que añadas con extensiones).
- **Panel lateral** con notificaciones e interruptores rápidos (wifi, bluetooth, micrófono, grabar pantalla…).
- **Lanzador** de aplicaciones con búsqueda, calculadora y fondos de pantalla.
- **Mostrar escritorio**: pulsa el escritorio en el que ya estás y las ventanas se apartan; púlsalo otra vez y vuelven a su sitio.

<!-- captura: docs/media/dashboard.webp — el dashboard abierto -->

### Nexus, los ajustes

Todo se configura desde **Nexus** (`Super+,`), sin tocar ficheros: actividades y su aspecto, paneles, atajos de teclado (los graba pulsando la combinación), red y VPN, bluetooth, audio, pantallas (resolución, frecuencia, escala y VRR), idioma, notificaciones y actualizaciones.

<!-- captura: docs/media/nexus.webp — Nexus en la página de Actividades -->

### Actualizaciones del sistema

Cuando hay paquetes nuevos (Arch, AUR o Flatpak), aparece un aviso en la barra. Desde ahí o desde Nexus actualizas con tu contraseña y ves el progreso en directo, sin abrir una terminal.

<!-- captura: docs/media/updates.webp — la página de actualizaciones con el progreso -->

### Extensiones y Things

Sylphrena se amplía con extensiones (hidratación, tareas, tu biblioteca de Steam con logros y tiempo de juego, VPN FortiClient…). Se instalan con un clic desde **Things**, el gestor de paquetes que viene con Sylphrena, que además busca e instala programas de Arch, AUR y Flatpak.

<!-- captura: docs/media/things.webp — Things en la sección Sylphrena -->

### Apps que vienen con Sylphrena

- **[Things](https://github.com/iMacnucintosh/things)**: gestor de paquetes y de extensiones.
- **[Seeker](https://github.com/iMacnucintosh/seeker)**: explorador de archivos, con el mismo aspecto que la shell.
- **kitty**: el terminal, que cambia de colores con tu actividad.

Las apps GTK y Qt también siguen el esquema de colores, y puedes pedir que ciertas apps se vean siempre en claro.

<!-- captura: docs/media/apps.webp — Seeker y Things junto a la shell -->

### Y además

- **Portapapeles** con historial, favoritos, búsqueda y vista previa de imágenes (`Super+Shift+V`).
- **Capturas y grabación de pantalla**, con indicador en la barra mientras grabas.
- **Pantalla de bloqueo** y **pantalla de inicio de sesión** con el mismo estilo.
- Notificaciones, control multimedia, perfil de audio de auriculares bluetooth y modo *no molestar*.
- Todo en **español** (y en inglés).

<!-- captura: docs/media/lock.webp — la pantalla de bloqueo -->

## Atajos básicos

| Atajo | Qué hace |
| --- | --- |
| `Super+Espacio` | Lanzador de aplicaciones |
| `Super+Q` | Terminal |
| `Super+E` | Explorador de archivos |
| `Super+C` | Cerrar la ventana |
| `Super+1` … `Super+0` | Ir a un escritorio |
| `Super+Ctrl+←` / `→` | Actividad anterior / siguiente |
| `Super+Tab` | Vista general de actividades |
| `Super+D` | Dashboard |
| `Super+,` | Nexus (ajustes) |
| `Super+Shift+V` | Portapapeles |
| `Super+L` | Bloquear |
| `Impr Pant` | Captura de pantalla |

Todos se cambian en Nexus → Teclado y ratón.

## Más información

| Documento | Contenido |
| --- | --- |
| [FEATURES.md](./FEATURES.md) | Guía de uso detallada de cada función |
| [CONFIG.md](./CONFIG.md) | Todas las opciones de `shell.json` |
| [CHANGELOG.md](./CHANGELOG.md) | Qué cambia en cada versión |
| [docs/DEVELOPMENT.md](./docs/DEVELOPMENT.md) | Instalación manual, compilar desde el código y contribuir |

¿Algo no funciona o echas algo en falta? [Abre una issue](https://github.com/iMacnucintosh/sylphrena-shell/issues/new).

## Créditos

Sylphrena empezó como un fork de [caelestia-shell](https://github.com/caelestia-dots/shell), de soramane, y hoy es un proyecto propio de [iMacnucintosh](https://github.com/iMacnucintosh). Gracias también a [Quickshell](https://github.com/outfoxxed/quickshell) ([@outfoxxed](https://github.com/outfoxxed)), sobre el que está construida, y a [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) y [Ax-Shell](https://github.com/Axenide/Ax-Shell) por la inspiración.

Licencia GPL-3.0.
