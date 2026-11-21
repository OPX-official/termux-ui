#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  OPX Termux UI — setup
#    -y / --yes     non-interactive (keep current config, use defaults)
#    --no-tools     skip optional packages
#    --no-banner    disable the banner
#    --no-shell     do not change the default shell
# ═══════════════════════════════════════════════════════════════════
set -uo pipefail

SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
OPX_HOME="${OPX_HOME:-$HOME/.opx/termux-ui}"
OPX_VERSION="$(cat "$SELF_DIR/VERSION" 2>/dev/null || printf '1.0.0')"
CONFIG_DIR="$HOME/.config/opx"
CONFIG_FILE="$CONFIG_DIR/config"
BACKUP_ROOT="$OPX_HOME/backups"
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
REPO="OPX-official/termux-ui"

ASSUME_YES=0; DO_TOOLS=1; DO_BANNER=1; DO_SHELL=1
for arg in "$@"; do
  case "$arg" in
    -y|--yes)    ASSUME_YES=1 ;;
    --no-tools)  DO_TOOLS=0 ;;
    --no-banner) DO_BANNER=0 ;;
    --no-shell)  DO_SHELL=0 ;;
    -h|--help)   sed -n '3,8p' "${BASH_SOURCE[0]}"; exit 0 ;;
  esac
done
[ "${OPX_NONINTERACTIVE:-0}" = "1" ] && ASSUME_YES=1

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  R=$'\033[0m'; B=$'\033[1m'; DIM=$'\033[2m'
  CY=$'\033[38;5;81m'; GN=$'\033[38;5;114m'; YL=$'\033[38;5;221m'
  RD=$'\033[38;5;203m'; MG=$'\033[38;5;213m'
else
  R=; B=; DIM=; CY=; GN=; YL=; RD=; MG=
fi

ui_head() { printf '\n%s %s%s%s\n' "${B}${CY}▌${R}" "$B" "$*" "$R"; }
step()    { printf '  %s▸%s %s\n' "$CY" "$R" "$*"; }
ok()      { printf '  %s✓%s %s\n' "$GN" "$R" "$*"; }
warn()    { printf '  %s!%s %s\n' "$YL" "$R" "$*"; }
die()     { printf '  %s✗%s %s\n' "$RD" "$R" "$*" >&2; exit 1; }

# ── environment ───────────────────────────────────────────────────
TERMUX=0
if [ -n "${TERMUX_VERSION:-}" ] || [ -d "/data/data/com.termux/files/usr" ]; then
  TERMUX=1
fi
PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"
if [ "$TERMUX" = 1 ]; then
  BIN_DIR="${OPX_BIN_DIR:-$PREFIX_DIR/bin}"
else
  BIN_DIR="${OPX_BIN_DIR:-$HOME/.local/bin}"
fi
mkdir -p "$OPX_HOME" "$CONFIG_DIR" "$BIN_DIR" 2>/dev/null

# ── prompts ───────────────────────────────────────────────────────
ask() {
  local q="$1" def="${2:-}" ans=""
  REPLY="$def"
  [ "$ASSUME_YES" = 1 ] && return 0
  if [ -r /dev/tty ]; then
    printf '  %s?%s %s %s[%s]%s ' "$MG" "$R" "$q" "$DIM" "$def" "$R" > /dev/tty
    IFS= read -r ans < /dev/tty || ans=""
  fi
  [ -n "$ans" ] && REPLY="$ans"
  return 0
}

ask_yn() {
  local q="$1" def="${2:-y}" ans=""
  REPLY="$def"
  [ "$ASSUME_YES" = 1 ] && return 0
  if [ -r /dev/tty ]; then
    printf '  %s?%s %s %s[%s]%s ' "$MG" "$R" "$q" "$DIM" "$def" "$R" > /dev/tty
    IFS= read -r ans < /dev/tty || ans=""
  fi
  [ -n "$ans" ] || ans="$def"
  case "$ans" in [Yy]*) REPLY=y ;; *) REPLY=n ;; esac
}

backup_file() {
  local f="$1"
  [ -e "$f" ] || return 0
  mkdir -p "$BACKUP_DIR"
  cp -a "$f" "$BACKUP_DIR/$(basename "$f")" 2>/dev/null && ok "backed up ${f/#$HOME/~}"
  return 0
}

pkg_install() {
  local core=0
  [ "${1:-}" = "--core" ] && { core=1; shift; }
  if [ "$TERMUX" != 1 ]; then
    [ "$core" = 1 ] && warn "not Termux — skipping: $*"
    return 0
  fi
  if ! command -v pkg >/dev/null 2>&1; then
    [ "$core" = 1 ] && die "pkg not found — is Termux installed correctly?"
    return 0
  fi
  step "pkg install $*"
  if pkg install -y "$@" </dev/null >/dev/null 2>&1; then
    ok "$*"
  else
    [ "$core" = 1 ] && warn "could not install: $*" || warn "optional package skipped: $*"
  fi
  return 0
}

# ── existing settings become the defaults (keeps `opx update` safe) ─
OPX_BANNER_TEXT="OPX TEAM"
OPX_BANNER_SUB="Termux UI  ·  by OPX Team"
OPX_BANNER_STYLE="1"
OPX_SHOW_INFO="1"
OPX_PROMPT_NAME="opxTeam"
OPX_PROMPT_ICON="⚡"
OPX_PROMPT_CHAR="#"
OPX_GIT_NAME=""
OPX_GIT_EMAIL=""
OPX_INSTALLED_VERSION=""
if [ -r "$CONFIG_FILE" ]; then
  . "$CONFIG_FILE"
  ok "existing configuration loaded"
fi

# ═══════════════════════════════════════════════════════════════════
#  1. wizard
# ═══════════════════════════════════════════════════════════════════
wizard() {
  ui_head "Personalise"
  if [ "$ASSUME_YES" = 1 ]; then
    ok "non-interactive: keeping current values"
    return 0
  fi
  printf '  %s(enter = keep the value in brackets)%s\n\n' "$DIM" "$R"

  ask "Banner title — big text shown on start" "$OPX_BANNER_TEXT"; OPX_BANNER_TEXT="$REPLY"
  ask "Banner subtitle" "$OPX_BANNER_SUB"; OPX_BANNER_SUB="$REPLY"
  ask "Banner style — 1 figlet · 2 boxed · 3 off" "$OPX_BANNER_STYLE"
  case "$REPLY" in 1|2|3) OPX_BANNER_STYLE="$REPLY" ;; *) OPX_BANNER_STYLE=2 ;; esac
  ask_yn "Show the time / device line under the banner?" "y"
  [ "$REPLY" = "y" ] && OPX_SHOW_INFO=1 || OPX_SHOW_INFO=0

  ask "Prompt name (shown as ⚡ name)" "$OPX_PROMPT_NAME"; OPX_PROMPT_NAME="$REPLY"
  ask "Prompt icon" "$OPX_PROMPT_ICON"; OPX_PROMPT_ICON="$REPLY"
  ask "Prompt character" "$OPX_PROMPT_CHAR"; OPX_PROMPT_CHAR="$REPLY"

  ask_yn "Install optional power tools (eza bat fzf jq tree htop)?" "y"
  [ "$REPLY" = "y" ] || DO_TOOLS=0
  ask_yn "Disable the banner?" "n"
  [ "$REPLY" = "y" ] && DO_BANNER=0

  if [ "$TERMUX" = 1 ]; then
    ask_yn "Make zsh your default shell in Termux?" "y"
    [ "$REPLY" = "y" ] || DO_SHELL=0
  fi

  ask "Git author name (optional, blank = skip)" "$OPX_GIT_NAME"; OPX_GIT_NAME="$REPLY"
  if [ -n "$OPX_GIT_NAME" ]; then
    ask "Git author email" "$OPX_GIT_EMAIL"; OPX_GIT_EMAIL="$REPLY"
  fi
  return 0
}

# ═══════════════════════════════════════════════════════════════════
#  2. payload
# ═══════════════════════════════════════════════════════════════════
install_payload() {
  ui_head "Files"
  if [ "$(cd "$SELF_DIR" && pwd -P)" != "$(cd "$OPX_HOME" && pwd -P)" ]; then
    cp -R "$SELF_DIR/shell" "$SELF_DIR/bin" "$SELF_DIR/assets" \
          "$SELF_DIR/setup.sh" "$SELF_DIR/install.sh" "$SELF_DIR/uninstall.sh" \
          "$SELF_DIR/VERSION" "$OPX_HOME/" 2>/dev/null
  fi
  chmod +x "$OPX_HOME/setup.sh" "$OPX_HOME/install.sh" "$OPX_HOME/uninstall.sh" \
           "$OPX_HOME/bin/opx" "$OPX_HOME/shell/opx.motd.sh" 2>/dev/null
  ok "payload → ${OPX_HOME/#$HOME/~}"
}

# ═══════════════════════════════════════════════════════════════════
#  3. packages + zsh plugins
# ═══════════════════════════════════════════════════════════════════
install_packages() {
  ui_head "Terminal engine"
  pkg_install --core zsh git curl
  pkg_install figlet
  if [ "$DO_TOOLS" = 1 ]; then
    pkg_install eza bat fzf jq tree htop ncurses-utils
  fi
}

clone_or_update() {
  local name="$1" url="$2" dir="$OPX_HOME/vendor/$1"
  mkdir -p "$OPX_HOME/vendor"
  if [ -d "$dir/.git" ]; then
    if git -C "$dir" pull --ff-only -q </dev/null >/dev/null 2>&1; then
      ok "$name updated"
    else
      warn "$name kept as is (no network)"
    fi
    return 0
  fi
  rm -rf "$dir"
  if command -v git >/dev/null 2>&1 &&
     GIT_TERMINAL_PROMPT=0 git clone --depth 1 -q "$url" "$dir" </dev/null >/dev/null 2>&1; then
    ok "$name installed"
  else
    warn "$name skipped — autosuggestions/highlighting stay off"
  fi
  return 0
}

install_plugins() {
  ui_head "Shell intelligence"
  clone_or_update zsh-autosuggestions   https://github.com/zsh-users/zsh-autosuggestions
  clone_or_update zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting
}

# ═══════════════════════════════════════════════════════════════════
#  4. configuration
# ═══════════════════════════════════════════════════════════════════
write_config() {
  ui_head "Configuration"
  mkdir -p "$CONFIG_DIR"
  backup_file "$CONFIG_FILE"
  local old_umask
  old_umask="$(umask)"
  umask 077
  {
    printf '# OPX Termux UI — generated %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '# edit me, then run: opx reload   (or `opx set KEY VALUE`)\n'
    printf 'OPX_INSTALLED_VERSION=%q\n' "$OPX_VERSION"
    printf 'OPX_BANNER_TEXT=%q\n'       "$OPX_BANNER_TEXT"
    printf 'OPX_BANNER_SUB=%q\n'        "$OPX_BANNER_SUB"
    printf 'OPX_BANNER_STYLE=%q\n'      "$OPX_BANNER_STYLE"
    printf 'OPX_SHOW_INFO=%q\n'         "$OPX_SHOW_INFO"
    printf 'OPX_PROMPT_NAME=%q\n'       "$OPX_PROMPT_NAME"
    printf 'OPX_PROMPT_ICON=%q\n'       "$OPX_PROMPT_ICON"
    printf 'OPX_PROMPT_CHAR=%q\n'       "$OPX_PROMPT_CHAR"
  } > "$CONFIG_FILE"
  umask "$old_umask"
  ok "config → ${CONFIG_FILE/#$HOME/~}"
}

install_zshrc() {
  ui_head "Shell hook"
  local rc="$HOME/.zshrc" mb="# >>> OPX TERMUX UI >>>" me="# <<< OPX TERMUX UI <<<"
  backup_file "$rc"
  if [ -f "$rc" ] && grep -qF "$mb" "$rc"; then
    ok "~/.zshrc already wired"
    return 0
  fi
  {
    [ -s "$rc" ] && printf '\n'
    printf '%s\n' "$mb"
    printf '[ -f %q ] && source %q\n' "$OPX_HOME/shell/opx.zshrc" "$OPX_HOME/shell/opx.zshrc"
    printf '%s\n' "$me"
  } >> "$rc"
  ok "~/.zshrc hooked"
}

install_motd() {
  ui_head "Banner"
  mkdir -p "$HOME/.termux"
  if [ "$DO_BANNER" = 0 ]; then
    backup_file "$HOME/.termux/motd.sh"
    rm -f "$HOME/.termux/motd.sh"
    ok "banner disabled"
    return 0
  fi
  if [ -f "$HOME/.termux/motd.sh" ] && \
     ! cmp -s "$HOME/.termux/motd.sh" "$OPX_HOME/shell/opx.motd.sh" 2>/dev/null; then
    backup_file "$HOME/.termux/motd.sh"
  fi
  cp "$OPX_HOME/shell/opx.motd.sh" "$HOME/.termux/motd.sh" 2>/dev/null
  chmod +x "$HOME/.termux/motd.sh" 2>/dev/null
  rm -f "$HOME/.hushlogin"
  ok "~/.termux/motd.sh installed"
}

install_termux_style() {
  ui_head "Termux look"
  mkdir -p "$HOME/.termux"

  local props="$HOME/.termux/termux.properties"
  backup_file "$props"
  if [ -f "$props" ] && grep -qE '^[[:space:]]*extra-keys[[:space:]]*=' "$props"; then
    warn "extra-keys already set — your key layout was kept"
  else
    { [ -s "$props" ] && printf '\n'; cat "$OPX_HOME/assets/termux.properties"; } >> "$props"
    ok "extra keys configured"
  fi

  local colors="$HOME/.termux/colors.properties"
  backup_file "$colors"
  cp "$OPX_HOME/assets/colors.properties" "$colors" 2>/dev/null
  ok "colour scheme applied"

  command -v termux-reload-settings >/dev/null 2>&1 && termux-reload-settings >/dev/null 2>&1
  return 0
}

install_cli() {
  ui_head "Command"
  mkdir -p "$BIN_DIR"
  cp "$OPX_HOME/bin/opx" "$BIN_DIR/opx" 2>/dev/null
  chmod +x "$BIN_DIR/opx" 2>/dev/null
  if command -v opx >/dev/null 2>&1 || [ -x "$BIN_DIR/opx" ]; then
    ok "opx → ${BIN_DIR/#$HOME/~}/opx"
  else
    warn "could not install the opx command"
  fi
}

set_shell() {
  ui_head "Default shell"
  if [ "$DO_SHELL" = 0 ] || [ "$TERMUX" != 1 ]; then
    warn "default shell unchanged — run 'exec zsh' to enter the new shell"
    return 0
  fi
  if [ -x "$PREFIX_DIR/bin/zsh" ]; then
    ln -sf "$PREFIX_DIR/bin/zsh" "$HOME/.termux/shell" 2>/dev/null
    if command -v chsh >/dev/null 2>&1; then
      chsh -s zsh </dev/null >/dev/null 2>&1 && ok "login shell → zsh"
    else
      ok "login shell → zsh (~/.termux/shell)"
    fi
  else
    warn "zsh binary not found — default shell unchanged"
  fi
  return 0
}

apply_git_identity() {
  [ -n "$OPX_GIT_NAME" ] || return 0
  ui_head "Git identity"
  git config --global user.name "$OPX_GIT_NAME" 2>/dev/null && ok "user.name = $OPX_GIT_NAME"
  [ -n "$OPX_GIT_EMAIL" ] && git config --global user.email "$OPX_GIT_EMAIL" 2>/dev/null \
    && ok "user.email = $OPX_GIT_EMAIL"
  return 0
}

# ═══════════════════════════════════════════════════════════════════
#  summary
# ═══════════════════════════════════════════════════════════════════
summary() {
  mkdir -p "$BACKUP_ROOT"
  printf '%s' "$BACKUP_DIR" > "$BACKUP_ROOT/LAST" 2>/dev/null
  local w=45 head="⚡ OPX Termux UI  v$OPX_VERSION"
  printf '\n'
  printf '  %s┌%s┐%s\n' "$CY" "$(printf '─%.0s' $(seq 1 "$w"))" "$R"
  printf '  %s│%s  %s%-*s%s%s│%s\n' "$CY" "$R" "$B" "$((w - 3))" "$head" "$R" "$CY" "$R"
  printf '  %s└%s┘%s\n\n' "$CY" "$(printf '─%.0s' $(seq 1 "$w"))" "$R"

  printf '  %sBanner%s   %s\n' "$DIM" "$R" "$OPX_BANNER_TEXT — $( [ "$OPX_BANNER_STYLE" = 3 ] && echo off || echo "style $OPX_BANNER_STYLE" )"
  printf '  %sPrompt%s   %s┌──(%s%s%s)─[~]  %s\n' "$DIM" "$R" "$CY" "$YL" "$OPX_PROMPT_ICON$OPX_PROMPT_NAME" "$CY" "$R"
  printf '           %s└─%s%s%s %s\n\n' "$CY" "$GN" "$OPX_PROMPT_CHAR" "$R" ""
  printf '  %snext%s  exec zsh        %s(or just reopen Termux)%s\n' "$DIM" "$R" "$DIM" "$R"
  printf '  %shelp%s  opx --help      %s(banner · theme · update · doctor · uninstall)%s\n' \
    "$DIM" "$R" "$DIM" "$R"
  printf '  %sundo%s  opx uninstall   %s(backups in %s)%s\n\n' \
    "$DIM" "$R" "$DIM" "${BACKUP_ROOT/#$HOME/~}" "$R"
}

# ═══════════════════════════════════════════════════════════════════
#  main
# ═══════════════════════════════════════════════════════════════════
printf '%s\n' "${B}${CY}  ⚡ OPX Termux UI${R} ${DIM}v${OPX_VERSION}${R}"

wizard
install_payload
install_packages
install_plugins
write_config
install_zshrc
install_motd
install_termux_style
install_cli
set_shell
apply_git_identity
summary
