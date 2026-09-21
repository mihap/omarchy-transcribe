# omarchy-transcribe

Right-click a video or audio file in Files (Nautilus), pick **Transcribe**,
choose a whisper model, and get `<same-name>.srt` next to the file. Also
available as **Transcribe** in the Omarchy menu and as `omarchy-transcribe`
on the command line.

Transcription runs locally with [whisper.cpp](https://github.com/ggerganov/whisper.cpp)
(`whisper-cli` from the Arch `whisper-cpp` package).

## Install

It is an Omarchy shell plugin (`manifest.json`, id `mihap.transcribe`):

```bash
omarchy plugin add https://github.com/mihap/omarchy-transcribe.git --enable
# or from a local checkout, same thing:
omarchy plugin add ~/my/omarchi-transcribe --enable
```

The plugin has no bar widget or panel; its only job is to run hooks when the
shell enables or disables it.

**Enable** links `omarchy-transcribe` into `~/.local/bin`, links the Nautilus
extension into `~/.local/share/nautilus-python/extensions`, and adds a
**Transcribe** row to the Omarchy menu
(`~/.config/omarchy/extensions/omarchy-menu.jsonc`). The first time, it also
opens a floating terminal that, without prompting:

- installs `whisper-cpp` (sudo prompt from pacman)
- downloads the `small` model (~500MB) into `~/.local/share/omarchy-transcribe/models/`
  unless a model is already available (see model directories below)
- installs `ggml-vulkan` for GPU acceleration when a Vulkan driver is present
  (CPU transcription works without it)

It records which of those packages it installed, so removing the plugin can
take out exactly those and leave a `whisper-cpp` you already had alone. If the
setup is interrupted (sudo cancelled, say), it runs again at the next shell
start until it completes, or until you disable the plugin.

Nautilus only loads extensions at startup. If Files is open, the right-click
entry appears after `nautilus -q` (which closes open Files windows) or at
your next login. The setup tells you but does not do it for you.

`omarchy plugin update mihap.transcribe` pulls the repo; the links follow it.
A hook log is kept at `~/.local/state/omarchy-transcribe/plugin.log`.

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
the last-used model first so Enter repeats the previous choice. Its last row,
**Download another model…**, opens a second picker of well-known models with
sizes, downloads the choice, and continues with it.

Multi-selecting files in Nautilus asks for the model once, then transcribes
the files one after another in the same floating terminal.

Both the menu row and the Nautilus entry run the command inside Omarchy's
floating terminal, so whisper's progress stays visible on long files.
Failures are also reported as a desktop notification.

## Adding models

```bash
omarchy-transcribe --list-available       # well-known models, sizes, which are installed
omarchy-transcribe --download medium      # fetch one by name
```

| Model | Size | Notes |
|---|---|---|
| `tiny`, `tiny.en` | 75M | fastest, rough |
| `base`, `base.en` | 142M | |
| `small`, `small.en` | 466M | default, good balance |
| `medium`, `medium.en` | 1.5G | better accuracy, slower |
| `large-v3-turbo` | 1.5G | near large-v3 accuracy, much faster |
| `large-v3` | 2.9G | best accuracy, slowest |
| `*-q5_0`, `*-q5_1` | ~1/3 | quantized variants of the above |

`.en` models are English-only and slightly better at it. Any other file name
under `ggerganov/whisper.cpp` on Hugging Face works with `--download` too.
You can also drop a `ggml-*.bin` into `~/.local/share/omarchy-transcribe/models/`
or into any directory listed in `MODEL_DIRS`.

## Configuration

`~/.config/omarchy-transcribe/config` is a sourced shell file. The shipped
defaults are `default/config` in the checkout; only put the keys you change
in your file.

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

## Disable and remove

Both are in Omarchy menu > Setup > Plugins, or on the command line:

```bash
omarchy plugin disable mihap.transcribe   # reversible
omarchy plugin remove mihap.transcribe    # deletes everything it brought
```

**Disable** unlinks the command and the Nautilus extension and removes the
menu row. The expensive parts stay: downloaded models and the packages.
Enable brings it back without a download.

**Remove** does what disable does and then opens a floating terminal that
purges everything the plugin brought: the models, its config and state, and
the packages its setup installed (`whisper-cpp`, `ggml-vulkan`), which needs
sudo. A package that was already on the machine before the setup is not
touched. Models in `MODEL_DIRS` (for example `~/.local/share/whisper`) are
never touched, and transcripts you made are never touched.

Remove while the plugin is **enabled**. Removing a plugin that is already
disabled destroys no service in the shell, so no hook runs and nothing is
purged. If you did that, the purge still runs by hand:

```bash
bash ~/.local/state/omarchy-transcribe/plugin-disable --purge
```

## Known Omarchy quirk: gum prompts in the old theme's colors

Omarchy loads a theme's gum colors into the environment at login. After
`omarchy theme set`, Hyprland refreshes its own environment, so terminals
opened by keybind are fine, but terminals that were already open, and
anything launched from the Omarchy menu, keep the old colors. Omarchy's
floating-terminal wrapper works around it by sourcing `omarchy-restart-gum`.
Other Omarchy commands you run from a terminal (`omarchy update`, for
example) do not. omarchy-transcribe itself shows no gum prompts, so it is
not affected.

Two user-side fixes, both optional:

```bash
# every new shell follows the current theme; add after the rc source in ~/.bashrc
command -v omarchy-restart-gum >/dev/null && source omarchy-restart-gum

# services and D-Bus-activated apps launched after a theme switch get the new colors
omarchy hook install theme-set contrib/gum-theme-env
```

For a terminal that is already open, `source omarchy-restart-gum` or
`exec bash` picks up the current theme.

## Layout

```
manifest.json                     Omarchy plugin manifest (id mihap.transcribe)
plugin/Service.qml                runs plugin/enable on load, plugin/disable on unload
plugin/enable                     links the command and extension, adds the menu row
plugin/setup                      first-time setup in a floating terminal (whisper-cpp, model, GPU)
plugin/disable                    unlink + menu row; on remove, purge in a floating terminal
bin/omarchy-transcribe            the command
bin/omarchy-transcribe-menu       add/remove the menu row (run by the hooks)
nautilus/omarchy-transcribe.py    Nautilus right-click entry (nautilus-python)
default/config                    shipped defaults
contrib/gum-theme-env             optional theme-set hook, see above
```
