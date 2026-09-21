import QtQuick
import Quickshell

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
// the disable hook without a shell restart. Enable is quiet and idempotent,
// and guards its first-time setup with a pending marker, so running it more
// than once is harmless.
//
// `omarchy plugin remove` deletes the checkout at about the same moment the
// shell destroys this object, so the disable hook cannot be read from the
// checkout. The enable hook therefore keeps a copy of it under
// ~/.local/state, and that copy is what runs on destruction. The disable
// hook checks shell.json so a shell restart does not tear anything down.
// Detached processes, so they outlive this object.
Item {
  id: root

  // Injected by the shell after creation and after every rescan.
  property var manifest: null

  readonly property string pluginDir: decodeURIComponent(
    String(Qt.resolvedUrl("..")).replace(/^file:\/\//, "")).replace(/\/$/, "")
  readonly property string disableCopy:
    (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
    + "/omarchy-transcribe/plugin-disable"

  // The reason lands in the shell journal (journalctl --user -u omarchy-shell),
  // next to the hook's own log under ~/.local/state.
  function enable(reason) {
    console.log("omarchy-transcribe: enable hook (" + reason + ")")
    Quickshell.execDetached(["bash", root.pluginDir + "/plugin/enable", root.pluginDir])
  }

  Component.onCompleted: enable("service created")
  onManifestChanged: if (manifest) enable("manifest injected")
  Component.onDestruction: Quickshell.execDetached(["bash", "-c",
    'if [[ -f "$1" ]]; then exec bash "$1" "$2"; else exec bash "$2/plugin/disable" "$2"; fi',
    "omarchy-transcribe-disable", root.disableCopy, root.pluginDir])
}
