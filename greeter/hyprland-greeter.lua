-- Compositor del greeter: alberga el greeter Quickshell Material You.
-- El boot del día va por [initial_session] (autologin), así que esto solo
-- corre tras un logout. Al cerrar qs, el compositor sale para que greetd
-- lance la sesión de usuario.
--
-- HOME/XDG deben venir ya del command de greetd (passwd del greeter es HOME=/).
-- Rollback a regreet: sustituir el exec_cmd de abajo por
--   regreet --style /etc/greetd/caelestia/regreet.css; hyprctl dispatch exit

hl.env("CAELESTIA_GREETER_DIR", "/etc/greetd/caelestia")
hl.env("HOME", "/var/lib/regreet")
hl.env("XDG_CACHE_HOME", "/var/lib/regreet/cache")
hl.env("XDG_CONFIG_HOME", "/var/lib/regreet/config")
hl.env("XDG_STATE_HOME", "/var/lib/regreet/state")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "")
hl.env("GDK_DEBUG", "no-portals")
-- Match the session keyboard (passwd greeter has no ~/.config/hypr).
hl.env("XKB_DEFAULT_LAYOUT", "es")
hl.env("XKB_DEFAULT_VARIANT", "")

hl.on("hyprland.start", function()
  hl.exec_cmd("/etc/greetd/caelestia/launch-qs.sh; exec /etc/greetd/caelestia/exit-compositor.sh")
end)

hl.config({
  input = {
    kb_layout = "es",
    kb_variant = "",
    kb_options = "",
  },
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    disable_hyprland_guiutils_check = true,
    -- Solid black after qs exits — shortens the VT flash before the user session.
    background_color = 0xff000000,
    force_default_wallpaper = 0,
  },
})
