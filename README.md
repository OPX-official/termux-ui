# ⚡ OPX Termux UI

A complete Termux makeover by **OPX Team** — professional banner, a two-line
prompt, fish-like autosuggestions, Tokyo Night colours and a phone-friendly
extra-keys row. One command, fully interactive setup.

```
┌──(⚡opxTeam)─[~]
└─#
```

## Install

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/OPX-official/termux-ui/main/install.sh)"
```

That is the whole thing. The wizard asks what the banner should say, which prompt
icon you want, whether to install the extra tools and whether zsh becomes your
default shell.

Install Termux from [F-Droid](https://f-droid.org/packages/com.termux/) or the
[GitHub releases](https://github.com/termux/termux-app/releases) — the Play Store
build is deprecated and the script will not work well there.

### Non-interactive

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/OPX-official/termux-ui/main/install.sh)" -- --yes
```

Flags: `--yes`, `--no-tools`, `--no-banner`, `--no-shell`.

## What it does

| Step | Result |
| --- | --- |
| Banner | `~/.termux/motd.sh` with a gradient title (figlet or boxed), subtitle and info line |
| Auto-fit | banner and prompt measure the real terminal size — resize, split screen or rotate and nothing wraps |
| Prompt | two-line prompt `┌──(⚡opxTeam)─[~]` / `└─#`, git branch on the right, command timer |
| Autosuggestions | previous commands appear as ghost text while you type |
| Highlighting | commands, paths and errors coloured as you type |
| History | 50 000 entries, shared between sessions, duplicate-free |
| `Ctrl-R` | fuzzy history search via fzf |
| Theme | Tokyo Night colours in `~/.termux/colors.properties` |
| Keys | two-row extra keys with arrows, Home/End, PgUp/PgDn — thumb-sized, no keyboard hunting |
| Tools | `eza`, `bat`, `fzf`, `jq`, `tree`, `htop`, `figlet` (optional) |

Everything already on your device is backed up first to
`~/.opx/termux-ui/backups/<timestamp>/`, and the newest path is stored in
`~/.opx/termux-ui/backups/LAST`.

## Auto-fit anywhere

The banner and prompt measure the terminal every time they draw, in real
display cells (wide and emoji glyphs count as two), so they stay sharp on any
screen:

| Terminal | What you get |
| --- | --- |
| wide (tablet, desktop, `tmux`) | figlet title centred, full path, git branch on the right |
| normal phone (≈40–60 cols) | figlet or boxed banner, two-line prompt, branch when it fits |
| narrow / split screen (< 34 cols) | compact one-line banner, one-line prompt `⚡opxTeam ~ #` |
| short screen (landscape keyboard open) | banner drops the info line, everything still fits one screen |

Long banner text, subtitles and deep paths are shortened with `…` instead of
wrapping. The prompt rebuilds itself the moment the window changes size
(`TRAPWINCH`), so rotating the phone needs no new session.

Force a style if you prefer one:

```bash
opx layout auto    # default: pick by screen width
opx layout two     # always the two-line prompt
opx layout one     # always the compact one-line prompt
```

## The `opx` command

```bash
opx banner "MY NAME"   # change the big banner text
opx sub "my subtitle"  # change the subtitle
opx prompt opxTeam     # change the prompt name
opx style 1|2|3        # figlet · boxed · off
opx layout auto|two|one  # prompt layout
opx set KEY VALUE      # set any OPX_* setting
opx list               # show current settings
opx theme              # re-apply the colour scheme
opx welcome            # print the banner
opx reload             # reload Termux settings
opx doctor             # health check
opx update             # fetch the latest version
opx uninstall          # remove everything
```

Settings live in `~/.config/opx/config`:

```bash
OPX_BANNER_TEXT="OPX TEAM"
OPX_BANNER_SUB="Termux UI  ·  by OPX Team"
OPX_BANNER_STYLE=1        # 1 figlet, 2 boxed, 3 off
OPX_SHOW_INFO=1
OPX_PROMPT_NAME="opxTeam"
OPX_PROMPT_ICON="⚡"
OPX_PROMPT_CHAR="#"
OPX_PROMPT_MODE="auto"    # auto | two | one
```

## Requirements

- Termux (F-Droid / GitHub build)
- ~40 MB of storage for zsh, figlet and the optional tools
- Internet for the first install

A Nerd Font is **not** required. The ⚡ icon renders with Termux's default font;
if a glyph ever shows as a box, change it with `opx set OPX_PROMPT_ICON ">"`.

## Uninstall

```bash
opx uninstall
```

This removes the shell hook, banner, theme, files and the `opx` command, and
restores your previous `~/.termux` files from the latest backup.
A copy of your `~/.zshrc` is left at `~/.zshrc.opx-removed.bak`.

## Troubleshooting

```bash
opx doctor      # what is installed and what is not
opx welcome     # render the banner right now
```

`.../motd.sh: not found` or `opx: not found` — old versions shipped
`#!/usr/bin/env bash`, and Termux has no `/usr/bin`. Since 1.1.1 every
installed script gets its shebang rewritten to `$PREFIX/bin/bash`. Re-run the
install one-liner once and the message is gone for good.

## Layout

```
install.sh               one-command entry point (downloads the repo)
setup.sh                 interactive wizard / installer
uninstall.sh             clean removal
bin/opx                  the command line
shell/opx.zshrc          prompt, plugins, aliases
shell/opx.motd.sh        banner renderer (installed to ~/.termux/motd.sh)
assets/colors.properties Tokyo Night palette
assets/termux.properties extra keys + dark UI
```

## License

MIT — do what you want, keep the credit.
