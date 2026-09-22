import QtQuick
import Quickshell
import Quickshell.Io // registers ProcessContext, which execDetached's object form converts to

// The plugin has no UI. The shell creates this service when the plugin is
// enabled (and again on every shell start while it stays enabled) and
// destroys it when the plugin is disabled or removed. Those two moments run
// the enable and disable hooks, which wire the command, the Nautilus entry,
// and the menu row into the user's home.
//
// keepLoaded in the manifest keeps this object alive across plugin rescans
// (any plugin being added, updated, or removed), which would otherwise
// destroy and recreate it and run both hooks each time. On a rescan the
// shell instead hands the kept instance a fresh manifest; that is the moment
// to re-run enable, so `omarchy plugin update` refreshes the stored copy of
// the disable hook without a shell restart. The shell injects the manifest
// several times per rescan (and once right after creation), so the runs are
// coalesced through a short timer. Enable is quiet and idempotent, and
// guards its first-time setup with a pending marker, so running it more
// than once is harmless anyway.
//
// `omarchy plugin remove` deletes the checkout at about the same moment the
// shell destroys this object, so the disable hook cannot be read from the
// checkout. The enable hook therefore keeps a copy of it under
// ~/.local/state, and that copy is what runs on destruction. The disable
// hook checks shell.json so a shell restart does not tear anything down.
// Detached processes, so they outlive this object.
//
// The hooks run automatically, without the user doing anything, so they
// must not be steerable from the environment: the shell's own environment
// is dropped, a fixed PATH of root-owned directories is set, the shell
// binary is named by absolute path, and only the variables the hooks and
// the floating setup/purge terminal need are copied across by name. That
// keeps a shadow `bash` in ~/.local/bin, or an inherited LD_PRELOAD /
// BASH_ENV, out of the picture. The hooks set the same PATH again
// themselves, and open the setup and purge terminal directly (systemd-run
// scope + xdg-terminal-exec, not the Omarchy helper, which goes through the
// uwsm app daemon and its unhardened session environment), so the terminal
// inherits exactly what is set here.
Item {
  id: root

  // Injected by the shell after creation and after every rescan.
  property var manifest: null

  readonly property string bash: "/usr/bin/bash"
  readonly property string pluginDir: decodeURIComponent(
    String(Qt.resolvedUrl("..")).replace(/^file:\/\//, "")).replace(/\/$/, "")
  readonly property string disableCopy:
    (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
    + "/omarchy-transcribe/plugin-disable"

  // Variables copied from the shell's environment, if set. Identity and
  // XDG dirs for the hooks, XDG_RUNTIME_DIR and the bus address for
  // systemd-run and notifications; session, display, and toolkit hints for
  // the floating terminal that setup and purge open. Nothing here names a
  // program: SHELL and TERMINAL are left out on purpose.
  readonly property var passthrough: [
    "HOME", "USER", "LOGNAME", "LANG", "LC_ALL", "LC_CTYPE",
    "XDG_RUNTIME_DIR", "XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_STATE_HOME",
    "XDG_CACHE_HOME", "XDG_CONFIG_DIRS", "XDG_DATA_DIRS",
    "XDG_CURRENT_DESKTOP", "XDG_SESSION_DESKTOP", "XDG_SESSION_TYPE",
    "XDG_SESSION_ID", "XDG_SESSION_CLASS", "XDG_SEAT", "XDG_VTNR",
    "WAYLAND_DISPLAY", "DISPLAY", "DBUS_SESSION_BUS_ADDRESS",
    "HYPRLAND_INSTANCE_SIGNATURE", "HYPRCURSOR_SIZE", "HYPRCURSOR_THEME",
    "XCURSOR_SIZE", "XCURSOR_THEME", "GDK_BACKEND", "GDK_SCALE",
    "QT_QPA_PLATFORM", "QT_QPA_PLATFORMTHEME", "QT_IM_MODULE", "XMODIFIERS",
    "INPUT_METHOD", "SDL_IM_MODULE"
  ]

  function hookEnvironment() {
    const env = {
      "PATH": "/usr/share/omarchy/bin:/usr/local/bin:/usr/bin:/bin",
      "OMARCHY_PATH": "/usr/share/omarchy"
    };
    for (const name of root.passthrough) {
      const value = Quickshell.env(name);
      if (value !== undefined && value !== null && String(value) !== "")
        env[name] = String(value);
    }
    return env;
  }

  function runHook(args) {
    Quickshell.execDetached({
      command: [root.bash].concat(args),
      environment: root.hookEnvironment(),
      clearEnvironment: true
    });
  }

  Timer {
    id: enableSoon
    interval: 500
    onTriggered: root.runHook([root.pluginDir + "/plugin/enable", root.pluginDir])
  }

  Component.onCompleted: enableSoon.restart()
  onManifestChanged: if (manifest) enableSoon.restart()
  Component.onDestruction: root.runHook(["-c",
    'if [[ -f "$1" ]]; then exec /usr/bin/bash "$1" "$2"; else exec /usr/bin/bash "$2/plugin/disable" "$2"; fi',
    "omarchy-transcribe-disable", root.disableCopy, root.pluginDir])
}
