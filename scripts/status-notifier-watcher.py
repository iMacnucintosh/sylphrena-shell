#!/usr/bin/env python3
"""Persistent org.kde.StatusNotifierWatcher for Sylphrena.

Quickshell's tray stack registers the watcher inside the `qs` process. A
`sylph shell -r` therefore drops every StatusNotifierItem. libappindicator
clients (Steam) re-bind when the name returns; Chromium/Electron trays
(Teams Flatpak) do not — minimize then leaves no window and no icon.

Running the watcher out-of-process keeps registrations across shell
restarts. Quickshell still acts as StatusNotifierHost and reads the
preexisting item list on connect (see quickshell status_notifier/host.cpp).

Also covers the gap left by Plasma's xembedsniproxy removal: Electron's
X11-tray fallback no longer has a bridge, so SNI must succeed and persist.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

import gi

gi.require_version("Gio", "2.0")
gi.require_version("GLib", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

WATCHER_NAME = "org.kde.StatusNotifierWatcher"
WATCHER_PATH = "/StatusNotifierWatcher"
WATCHER_IFACE = "org.kde.StatusNotifierWatcher"

_STATE_DIR = Path(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}") / "sylphrena"
_PIDFILE = _STATE_DIR / "status-notifier-watcher.pid"

INTROSPECTION_XML = f"""
<node>
  <interface name="{WATCHER_IFACE}">
    <method name="RegisterStatusNotifierItem">
      <arg direction="in" type="s" name="service"/>
    </method>
    <method name="RegisterStatusNotifierHost">
      <arg direction="in" type="s" name="service"/>
    </method>
    <property name="RegisteredStatusNotifierItems" type="as" access="read"/>
    <property name="IsStatusNotifierHostRegistered" type="b" access="read"/>
    <property name="ProtocolVersion" type="i" access="read"/>
    <signal name="StatusNotifierItemRegistered">
      <arg type="s" name="service"/>
    </signal>
    <signal name="StatusNotifierItemUnregistered">
      <arg type="s" name="service"/>
    </signal>
    <signal name="StatusNotifierHostRegistered"/>
    <signal name="StatusNotifierHostUnregistered"/>
  </interface>
</node>
"""


def _already_running() -> bool:
    """True only if a previous watcher process of ours is still alive.

    Do not key off the well-known bus name: Quickshell may own it until the
    next shell restart, and we must stay running to reclaim the name then.
    """
    if not _PIDFILE.is_file():
        return False
    try:
        pid = int(_PIDFILE.read_text().strip())
    except ValueError:
        return False
    if pid == os.getpid():
        return False
    try:
        cmdline = Path(f"/proc/{pid}/cmdline").read_bytes()
    except OSError:
        return False
    return b"status-notifier-watcher.py" in cmdline


def _write_pid() -> None:
    _STATE_DIR.mkdir(parents=True, exist_ok=True)
    _PIDFILE.write_text(str(os.getpid()))


def _qualify_item(service: str, sender: str) -> str:
    # Spec: callers pass either a bus name, a path, or "name/path".
    if service.startswith("/"):
        return f"{sender}{service}"
    if "/" not in service:
        return f"{service}/StatusNotifierItem"
    return service


def _service_alive(connection: Gio.DBusConnection, bus_name: str) -> bool:
    try:
        connection.call_sync(
            "org.freedesktop.DBus",
            "/org/freedesktop/DBus",
            "org.freedesktop.DBus",
            "GetNameOwner",
            GLib.Variant("(s)", (bus_name,)),
            GLib.VariantType("(s)"),
            Gio.DBusCallFlags.NONE,
            -1,
            None,
        )
        return True
    except GLib.Error:
        return False


class Watcher:
    def __init__(self) -> None:
        self.items: list[str] = []
        self.hosts: list[str] = []
        self.connection: Gio.DBusConnection | None = None
        self.registration_id = 0
        self._name_owner_id = 0
        node = Gio.DBusNodeInfo.new_for_xml(INTROSPECTION_XML)
        self.iface = node.interfaces[0]

    def run(self) -> int:
        if _already_running():
            return 0
        _write_pid()
        self._name_owner_id = Gio.bus_own_name(
            Gio.BusType.SESSION,
            WATCHER_NAME,
            Gio.BusNameOwnerFlags.NONE,
            self._on_bus_acquired,
            self._on_name_acquired,
            self._on_name_lost,
        )
        loop = GLib.MainLoop()
        try:
            loop.run()
        finally:
            if self._name_owner_id:
                Gio.bus_unown_name(self._name_owner_id)
            try:
                if _PIDFILE.is_file() and _PIDFILE.read_text().strip() == str(os.getpid()):
                    _PIDFILE.unlink(missing_ok=True)
            except OSError:
                pass
        return 0

    def _on_bus_acquired(self, connection: Gio.DBusConnection, _name: str) -> None:
        self.connection = connection
        self.registration_id = connection.register_object(
            WATCHER_PATH,
            self.iface,
            self._handle_method,
            self._handle_get_property,
            None,
        )
        # Drop items/hosts when their bus name vanishes.
        connection.signal_subscribe(
            "org.freedesktop.DBus",
            "org.freedesktop.DBus",
            "NameOwnerChanged",
            "/org/freedesktop/DBus",
            None,
            Gio.DBusSignalFlags.NONE,
            self._on_name_owner_changed,
        )

    def _on_name_acquired(self, _connection: Gio.DBusConnection, _name: str) -> None:
        # Claimed (or reclaimed after qs released it during a shell restart).
        pass

    def _on_name_lost(self, _connection: Gio.DBusConnection, _name: str) -> None:
        # Another watcher took the name (e.g. qs before we started). Stay alive
        # so bus_own_name can reclaim it when that process exits.
        pass

    def _emit(self, signal: str, args: GLib.Variant) -> None:
        if not self.connection:
            return
        self.connection.emit_signal(None, WATCHER_PATH, WATCHER_IFACE, signal, args)

    def _handle_method(
        self,
        _connection: Gio.DBusConnection,
        _sender: str | None,
        _object_path: str,
        _interface_name: str,
        method_name: str,
        parameters: GLib.Variant,
        invocation: Gio.DBusMethodInvocation,
    ) -> None:
        sender = invocation.get_sender() or ""
        if method_name == "RegisterStatusNotifierItem":
            raw = parameters.unpack()[0]
            qualified = _qualify_item(raw, sender)
            bus_name = qualified.split("/", 1)[0]
            if qualified in self.items:
                invocation.return_value(None)
                return
            if not self.connection or not _service_alive(self.connection, bus_name):
                invocation.return_dbus_error(
                    "org.kde.StatusNotifierWatcher.InvalidService",
                    f"invalid StatusNotifierItem {qualified}",
                )
                return
            self.items.append(qualified)
            self._emit("StatusNotifierItemRegistered", GLib.Variant("(s)", (qualified,)))
            invocation.return_value(None)
            return

        if method_name == "RegisterStatusNotifierHost":
            host = parameters.unpack()[0]
            if host in self.hosts:
                invocation.return_value(None)
                return
            if not self.connection or not _service_alive(self.connection, host):
                invocation.return_dbus_error(
                    "org.kde.StatusNotifierWatcher.InvalidService",
                    f"invalid StatusNotifierHost {host}",
                )
                return
            self.hosts.append(host)
            self._emit("StatusNotifierHostRegistered", None)
            invocation.return_value(None)
            return

        invocation.return_dbus_error(
            "org.freedesktop.DBus.Error.UnknownMethod",
            f"unknown method {method_name}",
        )

    def _handle_get_property(
        self,
        _connection: Gio.DBusConnection,
        _sender: str | None,
        _object_path: str,
        _interface_name: str,
        property_name: str,
    ) -> GLib.Variant | None:
        if property_name == "RegisteredStatusNotifierItems":
            return GLib.Variant("as", self.items)
        if property_name == "IsStatusNotifierHostRegistered":
            # Match Quickshell: always true so Electron trays do not wait forever
            # for StatusNotifierHostRegistered before calling RegisterStatusNotifierItem.
            return GLib.Variant("b", True)
        if property_name == "ProtocolVersion":
            return GLib.Variant("i", 0)
        return None

    def _on_name_owner_changed(
        self,
        _connection: Gio.DBusConnection,
        _sender: str,
        _object_path: str,
        _interface_name: str,
        _signal_name: str,
        parameters: GLib.Variant,
    ) -> None:
        name, _old, new = parameters.unpack()
        if new:
            return
        # Service vanished — drop matching items/hosts.
        gone_items = [i for i in self.items if i.startswith(name)]
        for item in gone_items:
            self.items.remove(item)
            self._emit("StatusNotifierItemUnregistered", GLib.Variant("(s)", (item,)))
        if name in self.hosts:
            self.hosts.remove(name)
            self._emit("StatusNotifierHostUnregistered", None)


def main() -> int:
    # Detach from a controlling TTY when launched via hyprland exec so the
    # watcher survives the launcher context (same idea as `sylph shell -d`).
    if os.environ.get("SYLPHRENA_SNI_WATCHER_FOREGROUND") != "1":
        if os.fork() != 0:
            return 0
        os.setsid()
        if os.fork() != 0:
            return 0
        sys.stdin.close()
        # Keep stdout/stderr for journald / redirectors when present.
    return Watcher().run()


if __name__ == "__main__":
    sys.exit(main())
