# omarchy-transcribe — Scope

Right-click a video in Nautilus (or pick one from the Omarchy menu), choose a
locally available whisper model, get `<same-dir>/<same-name>.srt`, overwritten
if it exists. Built the same way `omarchy-transcode` is built.

## Decisions (settled)

| Topic | Decision |
|---|---|
| Distribution | pacman package (PKGBUILD in this repo, `makepkg -si`). AUR later, optional. |
| whisper-cpp on uninstall | Not handled by hand. `depends=(whisper-cpp)`; removal runs `pacman -Rns` via `omarchy-pkg-drop`, so pacman removes whisper-cpp only if it was installed as a dependency and nothing else needs it. |
| Command name | `omarchy-transcribe` on PATH. The `omarchy` dispatcher only scans its own bin dir, so there is no `omarchy transcribe` route. Header comments (`# omarchy:*`) kept for consistency. |
| Right-click | nautilus-python `MenuProvider` at `/usr/share/nautilus-python/extensions/omarchy-transcribe.py` (system path, loaded by nautilus-python natively; no `/etc/skel` copying). |
| Launch wrapper | `omarchy-launch-floating-terminal-with-presentation`, same as transcode. |
| Menu row | `trigger.transcribe` appended to `~/.config/omarchy/extensions/omarchy-menu.jsonc` by the install script, with `"when":"omarchy-cmd-present omarchy-transcribe"` so it hides itself after removal. |
| Model dir (owned) | `~/.local/share/omarchy-transcribe/models/`. Deleted on remove (models are re-downloadable). |
| Model dirs (scanned) | Config key `MODEL_DIRS`, default includes `~/.local/share/whisper`. Scanned for the picker, never deleted. |
| Model download | `https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-<name>.bin`. Install downloads `small`. |
| Config | `~/.config/omarchy-transcribe/config`, sourced shell file. Defaults shipped at `/usr/share/omarchy-transcribe/config`. Absent user file = defaults. |
| State | Last-used model in `~/.local/state/omarchy-transcribe/last-model`, used to preselect in the picker. |
| Output | `whisper-cli -m <model> -f <input> -osrt -of <dir>/<stem>` → `<dir>/<stem>.srt`. Language default `auto`. |
| Inputs | video/* and audio/* (audio is free with whisper). |
| GPU | Optional `ggml-vulkan` gated on `omarchy-hw-vulkan`, as voxtype does. Unverified that whisper-cli picks it up; verify in T7. |

## Layout

```
PKGBUILD
bin/omarchy-transcribe
bin/omarchy-transcribe-install
bin/omarchy-transcribe-remove
nautilus/omarchy-transcribe.py
default/config
README.md
SCOPE.md
```

## Tasks

Mark a task `DONE` and record the commit sha when it is finished and verified.

| # | Task | Status | SHA |
|---|---|---|---|
| T1 | `bin/omarchy-transcribe`: args `[input] [model] [language]`; `omarchy-menu-file` for input (video+audio ext), `omarchy-menu-select` for model (scan `MODEL_DIRS`, show size subtext, preselect last-used), language default from config; run whisper-cli, write `.srt` beside input, notifications before/after, save last-model state. Header comments like transcode. | TODO | |
| T2 | `default/config`: `MODEL_DIRS`, `DEFAULT_MODEL`, `LANGUAGE`, `THREADS` with comments. Loader in T1 sources shipped defaults then user file. | TODO | |
| T3 | `nautilus/omarchy-transcribe.py`: copy of transcode.py shape; video/* + audio/* only; label "Transcribe" / "Transcribe N items"; launches via the floating-terminal wrapper; hidden when binaries missing. | TODO | |
| T4 | `bin/omarchy-transcribe-install`: gum confirm; download `small` into owned model dir if no model present anywhere; append `trigger.transcribe` row to user menu JSONC (idempotent, marker-guarded); optional `ggml-vulkan` if `omarchy-hw-vulkan`; `nautilus -q`; notification. | TODO | |
| T5 | `bin/omarchy-transcribe-remove`: remove menu row, owned model dir, config, state; `nautilus -q`; `omarchy-pkg-drop omarchy-transcribe` last. Prints what was left alone (scanned dirs). | TODO | |
| T6 | `PKGBUILD`: `depends=(whisper-cpp gum)`, `optdepends=(ggml-vulkan)`; installs bin/, nautilus extension, default config; `.install` post_install message pointing at `omarchy-transcribe-install`. `makepkg -si` succeeds, `namcap` clean. | TODO | |
| T7 | End-to-end test on this machine: install package, run install script, right-click a video in Nautilus → Transcribe → pick `small` → `.srt` appears beside it and overwrites on second run; menu row appears; GPU backend check; remove script leaves `~/.local/share/whisper` intact and pacman keeps explicitly installed whisper-cpp. | TODO | |
| T8 | `README.md`: install, usage, config keys, uninstall semantics (what pacman does with whisper-cpp, what is deleted vs kept). | TODO | |
