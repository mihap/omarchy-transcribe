# QA run — 2026-09-21

> Historical. This run covers 0.2.0 through 0.4.0, when the repo shipped a
> pacman package (`makepkg -si`, `omarchy-transcribe-install`,
> `omarchy-transcribe-remove`) alongside the plugin. 0.5.0 dropped the
> package; the plugin is the only install path and the current checklist is
> `QA.md`. The plugin-mode section at the end still describes the current
> hooks.

Tester: Claude (automated), on Mike's Omarchy 4.0.4 machine.
Code under test: e420e44 (fixes found during this run are included; the
package under test was built from 0ca79eb and re-verified against e420e44
for the changed paths).

## How it was run

No sudo password was available and no GUI could be driven, so the package
was **not** installed with pacman. Instead the three commands were symlinked
into `~/.local/bin` (which is on the desktop session's PATH) and every step
that does not need root or a mouse was executed against the real `$HOME`:
the real menu file, the real model directory, real notifications. The shim
was removed afterwards. `omarchy-pkg-drop` in step 9 was a genuine no-op
because the package was never installed, so removal ran without sudo.

Legend: PASS / FAIL / BLOCKED (needs sudo) / HUMAN (needs GUI interaction).

## Results

| Step | Item | Result | Notes |
|---|---|---|---|
| 0 | Clean state | PASS | Models, state, config, menu row all absent. whisper-cpp 1.9.3-1 still installed explicitly (not removed by the user yet). |
| 1 | `makepkg` builds | PASS | 7 files, deps `bash omarchy whisper-cpp gum curl file`, optdeps nautilus-python + ggml-vulkan, install script present. |
| 1 | `makepkg -si` / dependency install reason | BLOCKED | needs sudo. |
| 1 | `--help`, `--print-config`, `--list-models` | PASS | |
| 1 | Run with no model, non-tty | PASS | rc=1, hint printed, critical notification sent. |
| 2 | `omarchy-transcribe-install` | PASS | Non-tty: download and Vulkan skipped with hint, menu row inserted before final `}`, "Transcribe Ready" notification. |
| 2 | Model download | PASS | `--download small` → 466M in 38s. |
| 2 | Re-run install idempotent | PASS | "already available", "already present", 1 row. |
| 2 | Nautilus-running message | HUMAN | Nautilus was not running during the run. |
| 3a | Happy path, notifications, `.srt`, last-model | PASS | |
| 3b | Overwrite, no extra files | PASS | mtime changed, exactly one `qa-clip.srt`. |
| 3c | Language arg | PASS | `lang = en`. |
| 3d | Audio input | PASS | `~/Music/qa-clip.srt` written. |
| 3 | Model picker / file picker / `--path` / `--pick-model` | HUMAN | Quickshell popups. |
| 3e | Unknown model, unsupported file, bad download name, already-present download | PASS | rc=1/1/1/0. |
| 3e | Symlinked video | **FAIL → fixed** | `file` without `-L` reported `inode/symlink`. Fixed in e420e44 (`file -bL`); symlink now transcribes. |
| 3f | `--download base.en`, list shows both | PASS | 142M. |
| 4 | Nautilus right-click, multi-select, non-media exclusion | HUMAN | Extension logic unit-checked instead: mixed selection of mp4+mp3+txt+dir+png yields one item "Transcribe 2 items" with the two media paths; txt-only and png-only yield nothing; `_tools_available()` true with the command on PATH. |
| 5 | Omarchy menu row | HUMAN | Row is in the file with the floating-terminal action and a `when` guard. |
| 6 | Failure notification, whisper-cli path | PASS | Truncated mp4 → whisper-cli decode error → rc=1, critical notification, no `.srt` left. |
| 6 | Unreadable input | PASS (note) | Fails at the MIME check with a critical notification; whisper never runs, existing `.srt` untouched. QA.md step 6 rewritten to cover both cases. |
| 7 | GPU via ggml-vulkan | BLOCKED | ggml-vulkan not installed (needs sudo). Still unverified. |
| 8 | Config overrides | PASS | `LANGUAGE=en`, `THREADS=4`, `WHISPER_ARGS=--beam-size 3` all reflected in whisper output; `MODEL_DIRS` extra dir scanned; duplicate name deduped (owned dir wins). |
| 9 | Remove: Ctrl-C at sudo leaves everything | BLOCKED | No sudo prompt occurred. Covered earlier with a failing `omarchy-pkg-drop` stub (rc=1, nothing deleted). |
| 9 | Remove: menu restored, dirs deleted, outputs kept | PASS | Menu file byte-identical to the pre-run backup; 3 dirs gone; both `qa-clip.srt` kept; "Left alone" line printed. |
| 9 | pacman removes whisper-cpp | BLOCKED | Package never installed. |
| 10 | Reinstall from clean state | PASS | Install → download (37s) → install again idempotent → transcription works. |

## Human run (Mike), same day

- Step 1 sudo items: `makepkg -si` installed whisper-cpp as a dependency (install reason verified), post-install message shown. PASS.
- Step 2: gum prompts rendered in Tokyo Night colors on the Lupine theme. **FAIL → fixed** in bb1159f (`source omarchy-restart-gum` before gum). Needs a rebuild (`makepkg -si`) to pick up.
- Step 9: after `omarchy-transcribe-remove`, no package, system file, user dir, menu row, orphan, or pacman db entry left; whisper-cpp removed with the package; ggml-vulkan (accepted in step 2, explicit) and its ggml dependency remain, as QA.md predicts. PASS.

## Sign-off

Mike, 2026-09-21, on 0.2.0 (a67ef1d): install, per-user setup (promptless
model download + ggml-vulkan), Nautilus right-click, Omarchy menu, and
removal all confirmed working. One packaging pitfall found on the way:
`makepkg -si` reinstalled a stale same-version package instead of
rebuilding; fixed by bumping pkgver and documenting `makepkg -sif`.

## Plugin mode (0.4.0, 1300d27), live against the real shell

- `omarchy plugin add ~/my/omarchi-transcribe --enable --yes`: cloned from the
  local path, validated, enabled; service loaded and the enable hook ran.
  PASS.
- `omarchy plugin disable/enable/remove --yes/add/update`: all PASS; hook log
  shows each transition. **FAIL → fixed**: the first live disable was
  misread as a shell restart because the shell writes `shell.json` after
  destroying the service; the hook now polls for up to 4s.
- Hooks took the package-mode no-op branch throughout because the pacman
  package is installed on this machine. The full plugin-mode setup (links,
  extension, floating setup terminal) was verified in a fake HOME only.
  Menu-driven remove (Setup > Plugins > Remove Plugin) not yet run.
- Cleanup pass after the package was removed by hand: `omarchy plugin remove
  --yes` ran the disable hook in real plugin mode for the first time and
  **FAIL → fixed**: the checkout was already deleted by the time the hook
  finished polling, so `bin/omarchy-transcribe-menu` was gone and the row
  removal plus notification never ran. Second attempt showed the checkout can
  be gone before the hook even starts, so copying at hook start is not enough
  either. Final design (766ae78): `plugin/enable` stores a self-contained copy
  of the disable hook under `~/.local/state/omarchy-transcribe/`, and
  `Service.qml` runs that copy on destruction. Verified live in full plugin
  mode (pacman package absent): add `--enable` opened the setup terminal,
  `remove --yes` left no plugin dir, links, extension, menu row, or hook copy.
- Also found live: the shell creates the service twice on `plugin add
  --enable` (rescan, then enable), which opened two setup terminals; now a
  pending marker lets only the first one through (f1d1369).
- Mike: leaving models, state and packages behind after remove is too much.
  Reworked (1491948): disable is the reversible one (unlink + menu row,
  models and packages kept); remove additionally opens a floating terminal
  that purges models, config, state, and the packages the setup recorded in
  `installed-packages`. Live: add `--enable` then `remove --yes` left nothing
  in `$HOME` at all (466M of models included). whisper-cpp and ggml-vulkan
  stayed because they pre-dated the setup and were therefore not recorded;
  on a machine where the setup installs them, the purge removes them (sudo).

## Fixes made during the run

- `bin/omarchy-transcribe`: `file -bL` so symlinked media is accepted.
- `PKGBUILD`: URL updated to github.com/mihap (README already said so).
- `QA.md` step 6: use a truncated mp4 for the whisper failure path.
- `omarchy-transcribe.install`: post-install text no longer claims to reload Nautilus.
- `bin/omarchy-transcribe`, `bin/omarchy-transcribe-install`: gum prompts follow the current theme (bb1159f).

## State left on the machine

- `~/.local/share/omarchy-transcribe/models/ggml-small.bin` (466M) — kept so the GUI run does not re-download.
- `trigger.transcribe` row in `~/.config/omarchy/extensions/omarchy-menu.jsonc` — hidden by its `when` guard until the package is installed.
- `~/Videos/qa-clip.{mp4,srt}`, `~/Music/qa-clip.{mp3,srt}` — test media.
- Shim symlinks removed. No `~/.config/omarchy-transcribe`, no state dir.

## Remaining for a human

```bash
sudo pacman -Rns whisper-cpp          # so it comes back as a dependency
cd ~/my/omarchi-transcribe && makepkg -si
omarchy-transcribe-install            # will report model + menu row already present
nautilus -q
```

Then QA.md steps 3 (popups), 4, 5, 7, and the sudo parts of 1 and 9.
