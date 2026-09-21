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
| T1 | `bin/omarchy-transcribe`: args `[input] [model] [language]`; `omarchy-menu-file` for input (video+audio ext), `omarchy-menu-select` for model (scan `MODEL_DIRS`, show size subtext, preselect last-used), language default from config; run whisper-cli, write `.srt` beside input, notifications before/after, save last-model state. Header comments like transcode. Also `--download <model>` and `--list-models`. | DONE | c653fff, 7c5b624 |
| T2 | `default/config`: `MODEL_DIRS`, `DEFAULT_MODEL`, `LANGUAGE`, `THREADS` with comments. Loader in T1 sources shipped defaults then user file. | DONE | c653fff |
| T3 | `nautilus/omarchy-transcribe.py`: copy of transcode.py shape; video/* + audio/* only; label "Transcribe" / "Transcribe N items"; launches via the floating-terminal wrapper; hidden when binaries missing. | DONE | 1492004 |
| T4 | `bin/omarchy-transcribe-install`: gum confirm; download `small` into owned model dir if no model present anywhere; append `trigger.transcribe` row to user menu JSONC (idempotent, marker-guarded); optional `ggml-vulkan` if `omarchy-hw-vulkan`; `nautilus -q`; notification. | DONE | 7c5b624 |
| T5 | `bin/omarchy-transcribe-remove`: remove menu row, owned model dir, config, state; `nautilus -q`; `omarchy-pkg-drop omarchy-transcribe` last. Prints what was left alone (scanned dirs). | DONE | 7c5b624 |
| T6 | `PKGBUILD`: `depends=(whisper-cpp gum)`, `optdepends=(ggml-vulkan)`; installs bin/, nautilus extension, default config; `.install` post_install message pointing at `omarchy-transcribe-install`. `makepkg -f` builds; `namcap` not run (not installed, needs sudo to add). `makepkg -si` pending in T7. | DONE | 1af72de |
| R3 | No prompts: `omarchy-transcribe-install` downloads `DEFAULT_MODEL` when no model exists and installs `ggml-vulkan` whenever `omarchy-hw-vulkan` is true; the command's first-run path downloads the default model instead of asking. gum no longer used, dropped from `depends`; the R2 sourcing lines removed with it. | DONE | b4b1237 |
| R2 | QA finding: gum prompts in `omarchy-transcribe-install` and the first-run download prompt used the login-time theme colors (Tokyo Night on a Lupine desktop). Both now `source omarchy-restart-gum` first, as Omarchy's floating-terminal wrapper does. Verified under a pty with a gum stub: prompt foreground `#3264eb`, selected background `#d0d0d0` (Lupine). | DONE | bb1159f |
| T7 | End-to-end test on this machine: install package, run install script, right-click a video in Nautilus → Transcribe → pick `small` → `.srt` appears beside it and overwrites on second run; menu row appears; GPU backend check; remove script leaves `~/.local/share/whisper` intact and pacman keeps explicitly installed whisper-cpp. | PARTIAL | e420e44 — automated parts pass, see `QA-RESULTS-2026-09-21.md`; sudo (pacman install/remove, ggml-vulkan) and GUI (popups, Nautilus, menu) parts pending a human |
| T8 | `README.md`: install, usage, config keys, uninstall semantics (what pacman does with whisper-cpp, what is deleted vs kept). | DONE | 1af72de |
| R1 | Review fixes. Bugs: `inherit_errexit` + explicit `\|\| return` + stale `.srt` removed before run, so a failed whisper-cli exits 1; failures notify via `fail()` when stderr is not a tty; remove drops the package before any `rm -rf`. Smaller: model name validated against `^[A-Za-z0-9._-]+$`; last-model stores the resolved name; `WHISPER_ARGS` via `read -ra` (no glob); `local extra`; `--print-config` replaces the duplicated loader in install/remove; `--pick-model` lets the Nautilus multi-select ask once; menu row uses the floating-terminal wrapper; Nautilus is no longer quit, the user is told; PKGBUILD uses `git+file://$startdir` source and `nautilus-python` is an optdepend. shellcheck clean on all scripts. namcap still not installed. | DONE | 0164d2b |

## Verified so far without sudo

- R1: stubbed `whisper-cli` exiting 3 with a stale `.srt` present → rc=1, critical notification, stale file gone. `--download 'nope/../x'` rejected. Path model argument → `last-model` = `medium`. Remove with a failing `omarchy-pkg-drop` stub → rc=1, all three dirs and the menu row untouched; with a working stub → menu byte-identical, dirs gone. Multi-select command string parses under `bash -n` with spaces and quotes in paths. `makepkg -f` from the git source yields a binary identical to the committed one. `makepkg -S` builds a source tarball (PKGBUILD, .SRCINFO, .install only, since VCS sources are not bundled).

- T1: `bin/omarchy-transcribe /tmp/clip.mp4 small` on a 20s clip → `/tmp/clip.srt` in 6s; second run overwrites; unsupported file, unknown model, and bad download all fail cleanly with rc=1.
- T4/T5: run against a throwaway `$HOME` (with `XDG_*_HOME` unset) with stubbed `nautilus` and `omarchy-pkg-drop`: menu row inserted once, idempotent on re-run, parses as JSON after comment/trailing-comma stripping; remove restores the menu file byte-for-byte and deletes the three owned dirs.
- T6: `makepkg -f` produces `omarchy-transcribe-0.1.0-1-any.pkg.tar.zst` with the 7 expected files and deps `bash omarchy whisper-cpp nautilus-python gum curl file`, optdep `ggml-vulkan`.

## T7 runbook (needs a terminal for sudo)

The full step-by-step checklist with expected results is in `QA.md`. Short version:

```bash
cd ~/my/omarchi-transcribe
makepkg -si                   # builds from the committed HEAD; or: sudo pacman -U omarchy-transcribe-0.1.0-1-any.pkg.tar.zst
omarchy-transcribe-install    # models already in ~/.local/share/whisper are found, so no download
nautilus -q                   # so Files loads the new extension (closes open Files windows)
# 1. Files: right-click a video → Transcribe → pick small → <name>.srt appears; run again → overwritten; multi-select two files → one model prompt
# 2. Super+Alt+Space menu → Transcribe row present
# 3. GPU: after accepting ggml-vulkan, `whisper-cli -m ~/.local/share/whisper/ggml-small.bin -f /tmp/clip.mp4` should list a Vulkan device in its startup output
omarchy-transcribe-remove     # expect: ~/.local/share/whisper untouched, whisper-cpp kept (explicitly installed)
```
