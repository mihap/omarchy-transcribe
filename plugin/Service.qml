import QtQuick
import Quickshell

// The plugin has no UI. The shell creates this service when the plugin is
// enabled (and again on every shell start while it stays enabled) and
// destroys it when the plugin is disabled or removed. Those two moments run
// the enable and disable hooks, which wire the command, the Nautilus entry,
// and the menu row into the user's home.
//
// `omarchy plugin remove` deletes the checkout at about the same moment the
// shell destroys this object, so the disable hook cannot be read from the
// checkout. The enable hook therefore keeps a copy of it under
// ~/.local/state, and that copy is what runs on destruction. Both hooks are
// idempotent; the disable hook checks shell.json so a shell restart does
// not tear anything down. Detached processes, so they outlive this object.
Item {
  id: root

  readonly property string pluginDir: decodeURIComponent(
    String(Qt.resolvedUrl("..")).replace(/^file:\/\//, "")).replace(/\/$/, "")
  readonly property string disableCopy:
    (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
    + "/omarchy-transcribe/plugin-disable"

  Component.onCompleted: Quickshell.execDetached(["bash", root.pluginDir + "/plugin/enable", root.pluginDir])
  Component.onDestruction: Quickshell.execDetached(["bash", "-c",
    'if [[ -f "$1" ]]; then exec bash "$1" "$2"; else exec bash "$2/plugin/disable" "$2"; fi',
    "omarchy-transcribe-disable", root.disableCopy, root.pluginDir])
}
