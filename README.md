# omarchy-transcribe

Right-click a video or audio file in Files (Nautilus), pick **Transcribe**,
choose a whisper model, and get `<same-name>.srt` next to the file. Also
available as **Transcribe** in the Omarchy menu and as `omarchy-transcribe`
on the command line. Built the same way Omarchy's own `omarchy-transcode` is.

Transcription runs locally with [whisper.cpp](https://github.com/ggerganov/whisper.cpp)
(`whisper-cli` from the Arch `whisper-cpp` package).

## Install

```bash
git clone https://github.com/mikepevzner/omarchy-transcribe
cd omarchy-transcribe
makepkg -si            # builds the package from the committed checkout and installs it
omarchy-transcribe-install
```

`makepkg -si` pulls in `whisper-cpp` as a dependency. The Nautilus entry
needs `nautilus-python` (an optional dependency, present on every Omarchy
desktop). `omarchy-transcribe-install` does the per-user part:

- downloads the `small` model (~500MB) into `~/.local/share/omarchy-transcribe/models/`
  unless a model is already available (see model directories below)
- offers to install `ggml-vulkan` for GPU acceleration when Vulkan is detected
- adds a **Transcribe** row to the Omarchy menu (`~/.config/omarchy/extensions/omarchy-menu.jsonc`)

Nautilus only loads extensions at startup. If Files is open, the right-click
entry appears after `nautilus -q` (which closes open Files windows) or at
your next login. The install script tells you but does not do it for you.

## Usage

```bash
omarchy-transcribe                          # pick a file, then a model
omarchy-transcribe ~/Videos/talk.mp4        # pick a model
omarchy-transcribe ~/Videos/talk.mp4 small  # no prompts
omarchy-transcribe ~/Videos/talk.mp4 small en
omarchy-transcribe --path ~/Downloads       # limit the file picker
omarchy-transcribe --download medium        # fetch another model
omarchy-transcribe --list-models
omarchy-transcribe --pick-model             # just show the picker, print the name
omarchy-transcribe --print-config           # effective config as KEY=value
```

The output is always `<dir>/<stem>.srt` beside the input and is overwritten
on every run. Language defaults to `auto`.

The model picker lists every `ggml-*.bin` found in the model directories, with
the last-used model first so Enter repeats the previous choice.

Multi-selecting files in Nautilus asks for the model once, then transcribes
the files one after another in the same floating terminal.

Both the menu row and the Nautilus entry run the command inside Omarchy's
floating terminal, so whisper's progress stays visible on long files.
Failures are also reported as a desktop notification.

## Configuration

`~/.config/omarchy-transcribe/config` is a sourced shell file. The packaged
defaults are in `/usr/share/omarchy-transcribe/config`; only put the keys you
change in your file.

| Key | Default | Meaning |
|---|---|---|
| `MODEL_DIRS` | `$HOME/.local/share/whisper` | Extra directories to scan for `ggml-*.bin`, colon-separated. Never deleted. |
| `DEFAULT_MODEL` | `small` | Downloaded on first run and listed first when nothing has been used yet. |
| `LANGUAGE` | `auto` | Passed to `whisper-cli -l`. |
| `THREADS` | `$(nproc)` | Passed to `whisper-cli -t`. Empty uses whisper-cli's default. |
| `WHISPER_ARGS` | empty | Extra `whisper-cli` flags, whitespace-split. |

`~/.local/share/omarchy-transcribe/models/` is always scanned first. It is
the only directory the tool downloads into and the only one it deletes.

The last-used model is remembered in `~/.local/state/omarchy-transcribe/last-model`.

## Uninstall

```bash
omarchy-transcribe-remove
```

This runs `pacman -Rns omarchy-transcribe` via `omarchy-pkg-drop` first, so
nothing of yours is deleted if the sudo prompt is cancelled. It then removes
the menu row it added and deletes `~/.local/share/omarchy-transcribe`,
`~/.config/omarchy-transcribe` and `~/.local/state/omarchy-transcribe`.

What happens to `whisper-cpp` is decided by pacman, not by this tool:

- installed as a dependency of this package and needed by nothing else: removed
- installed explicitly by you, or needed by another package: kept

Models in `MODEL_DIRS` (for example `~/.local/share/whisper`) are never touched.

## Layout

```
bin/omarchy-transcribe            the command
bin/omarchy-transcribe-install    per-user setup (model, menu row, Nautilus reload)
bin/omarchy-transcribe-remove     per-user cleanup, then package removal
nautilus/omarchy-transcribe.py    Nautilus right-click entry (nautilus-python)
default/config                    packaged defaults -> /usr/share/omarchy-transcribe/config
PKGBUILD, omarchy-transcribe.install
```
