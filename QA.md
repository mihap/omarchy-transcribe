# QA checklist — omarchy-transcribe 0.1.0

Manual end-to-end test on an Omarchy machine. Tick each box; note the
actual result next to anything that deviates. Run everything as your normal
user in a terminal (sudo will prompt).

## 0. Clean state

Start from a machine that has never had whisper or this package.

```bash
pacman -Q whisper-cpp omarchy-transcribe ggml-vulkan   # all: "was not found"
ls ~/.local/share/whisper ~/.local/share/omarchy-transcribe \
   ~/.config/omarchy-transcribe ~/.local/state/omarchy-transcribe   # all: No such file
grep -c trigger.transcribe ~/.config/omarchy/extensions/omarchy-menu.jsonc   # 0
ls /usr/share/nautilus-python/extensions/   # no omarchy-transcribe.py
```

- [ ] All of the above hold. If whisper-cpp is present: `sudo pacman -Rns whisper-cpp`.

Test media: keep a short video handy, e.g.

```bash
ffmpeg -ss 60 -t 20 -i ~/Videos/<some>.mp4 -c copy ~/Videos/qa-clip.mp4
ffmpeg -i ~/Videos/qa-clip.mp4 -vn -c:a libmp3lame ~/Music/qa-clip.mp3
```

## 1. Build and install the package

```bash
cd ~/my/omarchi-transcribe
git status            # clean: the PKGBUILD builds the committed HEAD
makepkg -si
```

- [ ] makepkg resolves and installs `whisper-cpp` (and `ggml`, `ffmpeg` if missing) before building.
- [ ] Post-install message tells you to run `omarchy-transcribe-install`.
- [ ] `pacman -Qi whisper-cpp | grep 'Install Reason'` says **Installed as a dependency for another package**.
- [ ] `pacman -Q omarchy-transcribe` → `omarchy-transcribe 0.1.0-1`.
- [ ] `pacman -Ql omarchy-transcribe` lists: 3 files in `/usr/bin/`, `/usr/share/nautilus-python/extensions/omarchy-transcribe.py`, `/usr/share/omarchy-transcribe/config`, license, README.
- [ ] `omarchy-transcribe --help` prints usage, exit 0.
- [ ] `omarchy-transcribe --print-config` shows `MODEL_DIRS=/home/<you>/.local/share/whisper`, `DEFAULT_MODEL=small`, `LANGUAGE=auto`, `THREADS=<nproc>`.
- [ ] `omarchy-transcribe --list-models` prints nothing, exit 0.
- [ ] `omarchy-transcribe ~/Videos/qa-clip.mp4 small` (no model yet, in a terminal) prints "No whisper models found." and offers the download via gum. Answer **No** → exits 1 with the hint to run `--download small`.

## 2. Per-user setup

```bash
omarchy-transcribe-install
```

- [ ] gum asks to download `small` (~500MB). Answer Yes → curl progress bar → "Saved to ~/.local/share/omarchy-transcribe/models/ggml-small.bin (466M)".
- [ ] If Vulkan is present: gum asks to install `ggml-vulkan`. Record your answer: ______ (sudo prompt if Yes).
- [ ] "Added Transcribe to the Omarchy menu" and the file `~/.config/omarchy/extensions/omarchy-menu.jsonc` gained two lines just before the final `}`: a marker comment and the `trigger.transcribe` row.
- [ ] If Files was open: a message says Nautilus is running and how to restart it. No Files window was closed.
- [ ] Notification "Transcribe Ready" appears.
- [ ] Run `omarchy-transcribe-install` again → "Whisper models already available" with the small model listed, "Menu entry already present". No duplicate row in the JSONC. No second download.
- [ ] `nautilus -q` (accepts closing Files windows).

## 3. Command line

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
- [ ] `omarchy-transcribe --download base.en` → downloads `ggml-base.en.bin` (~148M). `--list-models` now shows `base.en` and `small`.

## 4. Nautilus right-click

Open Files, go to ~/Videos.

- [ ] Right-click `qa-clip.mp4` → context menu has **Transcribe**.
- [ ] Click it → floating Omarchy terminal with the logo → model popup (small listed first as the last used) → whisper progress in the terminal → notifications → "Done! Press any key to close".
- [ ] `qa-clip.srt` updated (check mtime).
- [ ] Select `qa-clip.mp4` and `qa-clip.mp3` (copy the mp3 into ~/Videos first) → context menu says **Transcribe 2 items** → **one** model popup → both files transcribed in sequence in the same terminal → both `.srt` files present.
- [ ] Right-click a `.txt` or a folder → no Transcribe entry.
- [ ] Right-click a `.png` → Transcode is offered, Transcribe is not.

## 5. Omarchy menu

- [ ] Open the Omarchy menu (Super+Alt+Space), type `transc` → both **Transcode** and **Transcribe** rows appear, Transcribe with the 󰨖 icon.
- [ ] Activate Transcribe → floating terminal opens → file popup → model popup → transcription → Done.
- [ ] Esc on the file popup → terminal shows Done and closes on keypress. No error notification.

## 6. Failure visibility (no terminal)

- [ ] Temporarily rename the model: `mv ~/.local/share/omarchy-transcribe/models/ggml-small.bin{,.bak}`; from the Omarchy menu pick Transcribe → clip → picker shows only `base.en` (if downloaded) or the "No whisper models found" failure arrives as a **critical notification**. Restore the file afterwards.
- [ ] Make whisper fail: `chmod 000 ~/Videos/qa-clip.mp4`; run Transcribe from Nautilus → critical notification "Transcribe failed: whisper-cli failed on qa-clip.mp4 with small"; `qa-clip.srt` was **removed** rather than left stale. `chmod 644` it back.

## 7. GPU (only if ggml-vulkan was installed)

```bash
whisper-cli -m ~/.local/share/omarchy-transcribe/models/ggml-small.bin -f ~/Videos/qa-clip.mp4 -osrt -of /tmp/gpu 2>&1 | grep -i -E 'vulkan|device'
```

- [ ] Output names a Vulkan device (e.g. `ggml_vulkan: 0 = <GPU name>`).
- [ ] Compare `total time` against the same command with `-ng` (whisper-cli's no-GPU flag) appended; the GPU run should be faster. Record both: CPU ______ ms, GPU ______ ms.
- [ ] If no Vulkan device shows up, note it in SCOPE T7 as "ggml-vulkan not picked up by whisper-cli" (known unverified).

## 8. Config overrides

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
- [ ] Remove `~/.config/omarchy-transcribe/config` and `~/models` afterwards, or keep the config to verify step 9 deletes it.

## 9. Removal

```bash
omarchy-transcribe-remove
```

- [ ] sudo prompts for a password. Press **Ctrl-C** → script aborts. Verify nothing was deleted: models dir, `~/.config/omarchy-transcribe`, state dir and the menu row are all still there, package still installed.
- [ ] Run again, enter the password → pacman removes `omarchy-transcribe` **and** `whisper-cpp` (it was a dependency), plus `ggml` if nothing else needs it. `ggml-vulkan`, if you installed it in step 2, stays (it was installed explicitly by `omarchy-pkg-add`); note that.
- [ ] Output: "Removed Transcribe from the Omarchy menu", "Deleted: …" listing the three dirs, "Left alone: models in ~/.local/share/whisper", and a Nautilus hint if Files is running.
- [ ] `~/.config/omarchy/extensions/omarchy-menu.jsonc` is byte-identical to before step 2 (`diff` against a copy you made, or check that the marker and row lines are gone and nothing else changed).
- [ ] `ls ~/.local/share/omarchy-transcribe ~/.config/omarchy-transcribe ~/.local/state/omarchy-transcribe` → all "No such file".
- [ ] `pacman -Q whisper-cpp omarchy-transcribe` → both "was not found". `pacman -Qdt` shows no new orphans.
- [ ] `/usr/share/nautilus-python/extensions/omarchy-transcribe.py` is gone. In Files, right-click a video → no Transcribe entry (immediately, since the binary is gone; fully after `nautilus -q`).
- [ ] Omarchy menu: Transcribe row gone.
- [ ] `~/Videos/qa-clip.srt` and `~/Music/qa-clip.srt` still exist (outputs are never touched).

## 10. Reinstall

- [ ] `makepkg -si && omarchy-transcribe-install` again works from the clean state: whisper-cpp comes back as a dependency, the model downloads again, the menu row is added once.

## Sign-off

| Area | Result | Notes |
|---|---|---|
| 1 Build/install | | |
| 2 Setup | | |
| 3 CLI | | |
| 4 Nautilus | | |
| 5 Menu | | |
| 6 Failure visibility | | |
| 7 GPU | | |
| 8 Config | | |
| 9 Removal | | |
| 10 Reinstall | | |

Tester: ________  Date: ________  Omarchy version: `omarchy version` → ________
