#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  OPX Termux UI — uninstall
#  Removes the shell hook, banner, theme and files.
#  Backups in ~/.opx/termux-ui/backups are restored where possible.
# ═══════════════════════════════════════════════════════════════════
set -uo pipefail

OPX_HOME="${OPX_HOME:-$HOME/.opx/termux-ui}"
CONFIG_DIR="$HOME/.config/opx"
PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"
BACKUP_ROOT="$OPX_HOME/backups"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  R=$'\033[0m'; B=$'\033[1m'; D=$'\033[2m'; C=$'\033[38;5;81m'
  G=$'\033[38;5;114m'; Y=$'\033[38;5;221m'; E=$'\033[38;5;203m'
else
  R=; B=; D=; C=; G=; Y=; E=
fi

ok()   { printf '  %s✓%s %s\n' "$G" "$R" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$R" "$*"; }

printf '\n%s %s\n\n' "${B}${C}▌${R}" "${B}Removing OPX Termux UI${R}"

# ── shell hook ────────────────────────────────────────────────────
rc="$HOME/.zshrc"
if [ -f "$rc" ] && grep -qF '# >>> OPX TERMUX UI >>>' "$rc"; then
  cp -a "$rc" "$HOME/.zshrc.opx-removed.bak" 2>/dev/null
  awk '
    /^# >>> OPX TERMUX UI >>>$/ { skip = 1; next }
    /^# <<< OPX TERMUX UI <<<$/ { skip = 0; next }
    !skip { print }
  ' "$rc" > "$rc.tmp" && mv "$rc.tmp" "$rc"
  ok "~/.zshrc hook removed (copy at ~/.zshrc.opx-removed.bak)"
  # the installer creates an empty ~/.zshrc when there was none
  [ -s "$rc" ] || rm -f "$rc"
fi

# ── restore termux files from the newest backup ───────────────────
LAST=""
[ -f "$BACKUP_ROOT/LAST" ] && LAST="$(cat "$BACKUP_ROOT/LAST" 2>/dev/null)"
restore() { # restore <file>
  local name="$1" src
  [ -n "$LAST" ] && [ -f "$LAST/$(basename "$1")" ] || return 1
  src="$LAST/$(basename "$1")"
  cp -a "$src" "$HOME/.termux/$(basename "$1")" 2>/dev/null && ok "restored $(basename "$1")" && return 0
  return 1
}

mkdir -p "$HOME/.termux"
restore "$HOME/.termux/motd.sh" || rm -f "$HOME/.termux/motd.sh"
restore "$HOME/.termux/colors.properties" || rm -f "$HOME/.termux/colors.properties"

# termux.properties is appended to, so on a first install there is no backup
props="$HOME/.termux/termux.properties"
if ! restore "$props"; then
  if [ -f "$props" ] && grep -q '^### OPX Termux UI' "$props"; then
    awk '/^### OPX Termux UI/ { exit } { print }' "$props" > "$props.tmp" && mv "$props.tmp" "$props"
    [ -s "$props" ] || rm -f "$props"
    ok "removed the OPX extra-keys block"
  fi
fi

# ── opx command ───────────────────────────────────────────────────
for p in "$PREFIX_DIR/bin/opx" "$HOME/.local/bin/opx"; do
  [ -e "$p" ] && rm -f "$p" && ok "removed $p"
done

# ── default shell back to bash ────────────────────────────────────
if [ -L "$HOME/.termux/shell" ]; then
  rm -f "$HOME/.termux/shell"
  ok "login shell restored to Termux default (bash)"
fi
if command -v chsh >/dev/null 2>&1 && [ -x "$PREFIX_DIR/bin/bash" ]; then
  chsh -s bash </dev/null >/dev/null 2>&1 && ok "chsh → bash"
fi

# ── files ─────────────────────────────────────────────────────────
rm -rf "$CONFIG_DIR"
rm -f "$HOME/.zcompdump-"* 2>/dev/null
rm -rf "$OPX_HOME"
ok "removed $OPX_HOME and $CONFIG_DIR"

command -v termux-reload-settings >/dev/null 2>&1 && termux-reload-settings >/dev/null 2>&1

printf '\n  %sdone — restart Termux to return to a clean bash shell%s\n\n' "$D" "$R"
