# QA checklist — omarchy-transcribe 0.5.0

Manual end-to-end test on an Omarchy machine. Tick each box; note the
actual result next to anything that deviates. Run everything as your normal
user in a terminal (sudo will prompt inside the floating setup terminal).

## 0. Clean state

Start from a machine that has never had whisper or this plugin.

```bash
pacman -Q whisper-cpp ggml-vulkan                       # both: "was not found"
omarchy plugin list | grep transcribe                   # nothing
ls ~/.local/share/whisper ~/.local/share/omarchy-transcribe \
   ~/.config/omarchy-transcribe ~/.local/state/omarchy-transcribe   # all: No such file
ls -la ~/.local/bin/omarchy-transcribe* ~/.local/share/nautilus-python/extensions/omarchy-transcribe.py  # none
grep -c trigger.transcribe ~/.config/omarchy/extensions/omarchy-menu.jsonc   # 0
```

- [ ] All of the above hold. If whisper-cpp is present: `sudo pacman -Rns whisper-cpp`.

Test media: keep a short video handy, e.g.

```bash
ffmpeg -ss 60 -t 20 -i ~/Videos/<some>.mp4 -c copy ~/Videos/qa-clip.mp4
ffmpeg -i ~/Videos/qa-clip.mp4 -vn -c:a libmp3lame ~/Music/qa-clip.mp3
```

## 1. Install

```bash
cd ~/my/omarchi-transcribe && git status         # clean; plugin add clones HEAD
omarchy plugin validate .                        # VALID
omarchy plugin add "$PWD" --enable --yes         # a URL works the same way
```

- [ ] Cloned into `~/.config/omarchy/plugins/mihap.transcribe/`; `omarchy plugin list` shows it `enabled third-party service`.
- [ ] Within a second, exactly **one** floating terminal opens: installs whisper-cpp (sudo prompt), "No whisper models found" is not printed (setup downloads first), curl progress bar → "Saved to ~/.local/share/omarchy-transcribe/models/ggml-small.bin (466M)", "Vulkan detected, installing ggml-vulkan" (if Vulkan is present) → installed, "Added Transcribe to the Omarchy menu", notification "Transcribe Ready", Done. No prompts other than sudo.
- [ ] `ls -la ~/.local/bin/omarchy-transcribe` → a link into the plugin dir. No `omarchy-transcribe-install`, `-remove`, or `-menu` links.
- [ ] `~/.local/share/nautilus-python/extensions/omarchy-transcribe.py` → a link into the plugin dir.
- [ ] `~/.local/state/omarchy-transcribe/` has `plugin.log`, `setup-done`, `plugin-disable`, and `installed-packages` listing `whisper-cpp` (and `ggml-vulkan` if it was installed). No `setup.pending`.
- [ ] `~/.config/omarchy/extensions/omarchy-menu.jsonc` gained two lines just before the final `}`: a marker comment and the `trigger.transcribe` row.
- [ ] If Files was open: the setup terminal said Nautilus is running and how to restart it. No Files window was closed.
- [ ] `omarchy-transcribe --help` prints usage, exit 0.
- [ ] `omarchy-transcribe --print-config` shows `MODEL_DIRS=/home/<you>/.local/share/whisper`, `DEFAULT_MODEL=small`, `LANGUAGE=auto`, `THREADS=<nproc>`.
- [ ] `omarchy-transcribe --list-models` → `small<TAB>/home/<you>/.local/share/omarchy-transcribe/models/ggml-small.bin`.
- [ ] `omarchy restart shell` → `plugin.log` gains one "disable … still enabled in shell.json after 4s" and one "enable … enabled quietly" block. Nothing removed, no terminal popped up, still exactly one row in the menu file.
- [ ] `omarchy plugin update mihap.transcribe --yes` (or `omarchy-shell shell rescanPlugins`) → `plugin.log` gains one "enable" block with **no** "disable" line before it (keepLoaded keeps the service across rescans; the Service coalesces the shell's repeated manifest injections); `plugin-disable` under the state dir has a fresh mtime; the checkout has the new commit.
- [ ] `nautilus -q` (accepts closing Files windows).

Interrupted setup, optional:

- [ ] On a second clean machine or after step 9: `omarchy plugin add "$PWD" --enable --yes`, press Ctrl-C at the sudo prompt → the terminal prints "Setup did not finish … disable the plugin", no `setup-done`. `omarchy restart shell` → the setup terminal opens again. Let it finish this time.

## 2. Command line

```bash
cd ~/Videos
omarchy-transcribe qa-clip.mp4 small
```

- [ ] Notification "Transcribing… qa-clip.mp4 with small", whisper progress in the terminal, then "Transcribed with small — Saved qa-clip.srt". Exit 0.
- [ ] `qa-clip.srt` exists beside the video with timestamped lines. `cat ~/.local/state/omarchy-transcribe/last-model` → `small`.
- [ ] Run the same command again → `qa-clip.srt` mtime changes (overwritten), no `qa-clip.srt.1` or similar.
- [ ] `omarchy-transcribe qa-clip.mp4 small en` → whisper output says `lang = en`.
- [ ] `omarchy-transcribe ~/Music/qa-clip.mp3 small` → `~/Music/qa-clip.srt` written (audio works).
- [ ] `omarchy-transcribe qa-clip.mp4` (no model) → Omarchy popup "Select model" listing `small` with its size as subtext. Pick it → transcription runs.
- [ ] `omarchy-transcribe` (no args) → popup "Transcribe video or audio" listing files from ~/Videos and ~/Music. Pick the clip → model popup → runs. Esc on either popup → exits 1, no notification.
- [ ] `omarchy-transcribe --path ~/Music` → file popup shows only ~/Music content.
- [ ] `omarchy-transcribe --pick-model` → model popup, prints `small`, exit 0.
- [ ] `omarchy-transcribe qa-clip.mp4 nonexistent` → "Model not found: nonexistent (run: omarchy-transcribe --download nonexistent)", exit 1.
- [ ] `omarchy-transcribe ~/.bashrc small` → "Unsupported file type: text/plain", exit 1.
- [ ] `omarchy-transcribe --download 'bad/../name'` → "Invalid model name", exit 1, nothing created under the models dir.
- [ ] `omarchy-transcribe --download small` → "already present", exit 0.
- [ ] `omarchy-transcribe --download base.en` → downloads `ggml-base.en.bin` (~142M). `--list-models` now shows `base.en` and `small`.
- [ ] `omarchy-transcribe --list-available` → table of 14 models with SIZE and NOTE columns; `small` and `base.en` marked `installed`.
- [ ] `omarchy-transcribe qa-clip.mp4` → picker's last row is **Download another model…**. Pick it → second popup lists only models not yet installed, with sizes → pick `tiny` → download progress in the terminal → transcription runs with tiny → `last-model` is `tiny`.

## 3. Nautilus right-click

Open Files, go to ~/Videos.

- [ ] Right-click `qa-clip.mp4` → context menu has **Transcribe**.
- [ ] Click it → floating Omarchy terminal with the logo → model popup (tiny listed first as the last used) → whisper progress in the terminal → notifications → "Done! Press any key to close".
- [ ] `qa-clip.srt` updated (check mtime).
- [ ] Select `qa-clip.mp4` and `qa-clip.mp3` (copy the mp3 into ~/Videos first) → context menu says **Transcribe 2 items** → **one** model popup → both files transcribed in sequence in the same terminal → both `.srt` files present.
- [ ] Right-click a `.txt` or a folder → no Transcribe entry.
- [ ] Right-click a `.png` → Transcode is offered, Transcribe is not.

## 4. Omarchy menu

- [ ] Open the Omarchy menu (Super+Alt+Space), type `transc` → both **Transcode** and **Transcribe** rows appear, Transcribe with the 󰨖 icon.
- [ ] Activate Transcribe → floating terminal opens → file popup → model popup → transcription → Done.
- [ ] Esc on the file popup → terminal shows Done and closes on keypress. No error notification.

## 5. Failure visibility (no terminal)

- [ ] Temporarily rename the model: `mv ~/.local/share/omarchy-transcribe/models/ggml-small.bin{,.bak}`; from the Omarchy menu pick Transcribe → clip → picker shows only the other models. Restore the file afterwards.
- [ ] Make whisper fail on a file that passes the MIME check: `head -c 200000 ~/Videos/qa-clip.mp4 > ~/Videos/qa-broken.mp4` (truncated mp4, still `video/mp4`); run Transcribe on it from Nautilus → critical notification "Transcribe failed: whisper-cli failed on qa-broken.mp4 with small"; neither `qa-broken.srt` nor `qa-broken.partial.srt` is left behind. Delete the broken file afterwards.
- [ ] Previous transcript survives a failure: `cp ~/Videos/qa-clip.srt /tmp/keep.srt`, then `omarchy-transcribe ~/Videos/qa-clip.mp4 small` with whisper made to fail (e.g. `WHISPER_ARGS="--bogus-flag"` in the config) → exit 1, `diff /tmp/keep.srt ~/Videos/qa-clip.srt` is empty. Undo the config change.
- [ ] `chmod 000 ~/Videos/qa-clip.mp4`; run Transcribe → critical notification about no read permission (fails before whisper runs; the existing `qa-clip.srt` is left as is). `chmod 644` it back.

## 6. GPU (only if ggml-vulkan was installed)

```bash
whisper-cli -m ~/.local/share/omarchy-transcribe/models/ggml-small.bin -f ~/Videos/qa-clip.mp4 -osrt -of /tmp/gpu 2>&1 | grep -i -E 'vulkan|device'
```

- [ ] Output names a Vulkan device (e.g. `ggml_vulkan: 0 = <GPU name>`).
- [ ] Compare `total time` against the same command with `-ng` (whisper-cli's no-GPU flag) appended; the GPU run should be faster. Record both: CPU ______ ms, GPU ______ ms.
- [ ] If no Vulkan device shows up, note it in SCOPE as "ggml-vulkan not picked up by whisper-cli" (known unverified).

## 7. Config overrides

```bash
mkdir -p ~/.config/omarchy-transcribe
cat > ~/.config/omarchy-transcribe/config <<'EOF'
LANGUAGE="en"
THREADS="4"
WHISPER_ARGS="--beam-size 3"
EOF
omarchy-transcribe --print-config
omarchy-transcribe ~/Videos/qa-clip.mp4 small
```

- [ ] `--print-config` shows `LANGUAGE=en`, `THREADS=4`, `WHISPER_ARGS=--beam-size\ 3`.
- [ ] whisper output shows `4 threads` and `lang = en` and `3 beams`.
- [ ] Put a model in another directory and point at it: `mkdir -p ~/models && cp ~/.local/share/omarchy-transcribe/models/ggml-base.en.bin ~/models/` and add `MODEL_DIRS="$HOME/models"` to the config → `--list-models` still lists `base.en` once (owned dir wins) and the picker shows no duplicate.
- [ ] Remove `~/models` afterwards; keep the config to verify step 9 deletes it.

## 8. Disable and enable

```bash
omarchy plugin disable mihap.transcribe
```

- [ ] Notification "Transcribe disabled". `~/.local/bin/omarchy-transcribe` and the extension link are gone; the menu row is gone from the file (`grep -c trigger.transcribe` → 0); `omarchy-transcribe` is no longer on PATH.
- [ ] Models still in `~/.local/share/omarchy-transcribe/models`; `~/.local/state/omarchy-transcribe/` still has `setup-done`, `installed-packages`, `plugin-disable`; whisper-cpp still installed.
- [ ] In Files, right-click a video → no Transcribe entry (immediately, since the command is gone).

```bash
omarchy plugin enable mihap.transcribe
```

- [ ] Links and menu row back, quietly: no terminal, no download; `plugin.log` says "enabled quietly". `omarchy-transcribe qa-clip.mp4 small` works.

## 9. Remove

Super+Space → Setup → Plugins → Remove Plugin → pick Transcribe → the floating terminal asks to delete (git repo) → Yes. Or: `omarchy plugin remove mihap.transcribe --yes`.

- [ ] A **second** floating terminal opens: "Transcribe plugin removed.", "Cleaning up unused dependencies..." (sudo prompt), "Deleting downloaded models and settings:" with sizes, "Cleanup finished.", notification "Transcribe removed".
- [ ] Afterwards: no `~/.config/omarchy/plugins/mihap.transcribe`, no link in `~/.local/bin`, no extension link, `grep -c trigger.transcribe` on the menu file → 0 and the file is otherwise as it was before step 1, no `~/.local/share/omarchy-transcribe`, no `~/.config/omarchy-transcribe`, no `~/.local/state/omarchy-transcribe`.
- [ ] `pacman -Q whisper-cpp ggml-vulkan` → both not found (they were absent at step 0). `pacman -Qdt` shows no new orphans.
- [ ] `~/Videos/qa-clip.srt` and `~/Music/qa-clip.srt` still exist (outputs are never touched). `~/.local/share/whisper`, if you had one, is untouched.
- [ ] Omarchy menu: Transcribe row gone. Files: no Transcribe entry (fully after `nautilus -q`).

Variants, each after a fresh step 1:

- [ ] Cancel the sudo prompt (Ctrl-C) in the purge terminal → packages stay, models/settings still deleted, "Cleanup finished with leftovers" and a critical notification naming the packages and the command to remove them.
- [ ] Disable first, then remove → no purge terminal (documented: no service is destroyed). `bash ~/.local/state/omarchy-transcribe/plugin-disable --purge` then does the purge by hand with the same output as above.

## 10. Reinstall

- [ ] `omarchy plugin add "$PWD" --enable --yes` again → full first-time setup again in one terminal, since everything was purged. Transcription works.

## Sign-off

| Area | Result | Notes |
|---|---|---|
| 1 Install | | |
| 2 CLI | | |
| 3 Nautilus | | |
| 4 Menu | | |
| 5 Failure visibility | | |
| 6 GPU | | |
| 7 Config | | |
| 8 Disable/enable | | |
| 9 Remove | | |
| 10 Reinstall | | |

Tester: ________  Date: ________  Omarchy version: `omarchy version` → ________
