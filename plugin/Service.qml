import QtQuick
import Quickshell

// The plugin has no UI. The shell creates this service when the plugin is
// enabled (and again on every shell start while it stays enabled) and
// destroys it when the plugin is disabled or removed. Those two moments run
// the enable and disable hooks, which wire the command, the Nautilus entry,
// and the menu row into the user's home. Both hooks are idempotent and the
// disable hook checks shell.json so a shell restart does not tear anything
// down. Detached processes so they outlive this object.
Item {
  id: root

  readonly property string pluginDir: decodeURIComponent(
    String(Qt.resolvedUrl("..")).replace(/^file:\/\//, "")).replace(/\/$/, "")

  Component.onCompleted: Quickshell.execDetached(["bash", root.pluginDir + "/plugin/enable"])
  Component.onDestruction: Quickshell.execDetached(["bash", root.pluginDir + "/plugin/disable"])
}
