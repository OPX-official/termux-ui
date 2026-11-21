#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  OPX Termux UI — installer
#  https://github.com/OPX-official/termux-ui
#
#  One command:
#    bash -c "$(curl -fsSL https://raw.githubusercontent.com/OPX-official/termux-ui/main/install.sh)"
#
#  Options:
#    --yes        non-interactive, accept defaults
#    --no-tools   skip optional packages
#    --no-banner  no banner/MOTD
#    --no-shell   do not change the default shell
# ═══════════════════════════════════════════════════════════════════
set -uo pipefail

OPX_REPO="OPX-official/termux-ui"
OPX_BRANCH="${OPX_BRANCH:-main}"
OPX_HOME="${OPX_HOME:-$HOME/.opx/termux-ui}"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  R=$'\033[0m'; B=$'\033[1m'; D=$'\033[2m'
  C=$'\033[38;5;81m'; G=$'\033[38;5;114m'; E=$'\033[38;5;203m'
else
  R=; B=; D=; C=; G=; E=
fi

have() { command -v "$1" >/dev/null 2>&1; }

printf '%s\n\n' "${C}${B}  OPX Termux UI${R} ${D}· personalising your Termux${R}"

# ── make sure we can download ──────────────────────────────────────
if ! have curl && ! have wget; then
  if have pkg; then
    printf '  %s▸%s installing curl\n' "$C" "$R"
    pkg install -y curl </dev/null >/dev/null 2>&1
  fi
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/opx-install.XXXXXX")" || {
  printf '  %s✗%s could not create a temporary directory\n' "$E" "$R" >&2
  exit 1
}

SRC_DIR=""
TARBALL="https://codeload.github.com/${OPX_REPO}/tar.gz/refs/heads/${OPX_BRANCH}"

printf '  %s▸%s downloading %s (%s)\n' "$C" "$R" "$OPX_REPO" "$OPX_BRANCH"
if have curl; then
  curl -fsSL "$TARBALL" -o "$TMP/repo.tar.gz" 2>/dev/null || rm -f "$TMP/repo.tar.gz"
elif have wget; then
  wget -qO "$TMP/repo.tar.gz" "$TARBALL" 2>/dev/null || rm -f "$TMP/repo.tar.gz"
fi

if [ -s "$TMP/repo.tar.gz" ] && tar -xzf "$TMP/repo.tar.gz" -C "$TMP" 2>/dev/null; then
  SRC_DIR="$(find "$TMP" -maxdepth 1 -mindepth 1 -type d | head -n 1)"
fi

# fallback: git clone
if [ -z "${SRC_DIR:-}" ] || [ ! -d "${SRC_DIR:-/nonexistent}" ]; then
  if ! have git && have pkg; then
    printf '  %s▸%s installing git\n' "$C" "$R"
    pkg install -y git </dev/null >/dev/null 2>&1
  fi
  if have git; then
    printf '  %s▸%s falling back to git clone\n' "$C" "$R"
    GIT_TERMINAL_PROMPT=0 git clone --depth 1 --branch "$OPX_BRANCH" \
      "https://github.com/${OPX_REPO}.git" "$TMP/src" </dev/null >/dev/null 2>&1 \
      && SRC_DIR="$TMP/src"
  fi
fi

if [ -z "${SRC_DIR:-}" ] || [ ! -f "$SRC_DIR/setup.sh" ]; then
  printf '  %s✗%s download failed. Check your connection and try again.\n' "$E" "$R" >&2
  rm -rf "$TMP"
  exit 1
fi

# ── install the payload, then hand over to the wizard ─────────────
mkdir -p "$OPX_HOME" 2>/dev/null
cp -R "$SRC_DIR/." "$OPX_HOME/" 2>/dev/null
chmod +x "$OPX_HOME/install.sh" "$OPX_HOME/setup.sh" "$OPX_HOME/uninstall.sh" \
         "$OPX_HOME/bin/opx" "$OPX_HOME/shell/opx.motd.sh" 2>/dev/null
rm -rf "$TMP"

printf '  %s✓%s files → %s\n\n' "$G" "$R" "$OPX_HOME"
exec bash "$OPX_HOME/setup.sh" "$@"
