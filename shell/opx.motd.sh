#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  OPX Termux UI — welcome banner (installed as ~/.termux/motd.sh)
#
#  Auto-fits any terminal size. Every line is measured in real
#  display cells (wide/emoji glyphs count as two), truncated with …
#  when it does not fit, and re-measured on every new session — so a
#  30-column split or a 200-column desktop terminal both look right
#  and never wrap.
#
#  Configured by ~/.config/opx/config — run `opx set KEY VALUE`.
# ═══════════════════════════════════════════════════════════════════
[ -t 1 ] || exit 0
[ -r "$HOME/.config/opx/config" ] && . "$HOME/.config/opx/config"

: "${OPX_BANNER_TEXT:=OPX TEAM}"
: "${OPX_BANNER_SUB:=Termux UI · by OPX Team}"
: "${OPX_BANNER_STYLE:=1}"
: "${OPX_SHOW_INFO:=1}"
: "${OPX_INSTALLED_VERSION:=1.1.0}"

[ "$OPX_BANNER_STYLE" = "3" ] && exit 0

R=$'\033[0m'; DIM=$'\033[2m'; B=$'\033[1m'
CY=$'\033[38;2;125;207;255m'
MUTE=$'\033[38;2;86;95;137m'

# ── terminal size ─────────────────────────────────────────────────
# /dev/tty knows the real size even when COLUMNS is stale or unset.
term_size() {
  local size="" w="" h=""
  if [ -r /dev/tty ] && command -v stty >/dev/null 2>&1; then
    size="$(stty size 2>/dev/null < /dev/tty)"
  fi
  [ -n "$size" ] || size="$(stty size 2>/dev/null)"
  if [ -n "$size" ]; then
    h="${size%% *}"; w="${size##* }"
  fi
  if [ -z "$w" ] || [ -z "$h" ]; then
    if command -v tput >/dev/null 2>&1; then
      w="${w:-$(tput cols 2>/dev/null)}"
      h="${h:-$(tput lines 2>/dev/null)}"
    fi
  fi
  case "${w:-}" in ''|*[!0-9]*) w="${COLUMNS:-80}" ;; esac
  case "${h:-}" in ''|*[!0-9]*) h="${LINES:-24}" ;; esac
  case "$w" in ''|*[!0-9]*) w=80 ;; esac
  case "$h" in ''|*[!0-9]*) h=24 ;; esac
  (( w < 20 )) && w=20
  (( h < 5 )) && h=5
  W=$w; H=$h
}
term_size

# ── display width (CJK + emoji occupy two cells) ───────────────────
CHAR_COLS=1
char_cols() { # <one character> → CHAR_COLS
  local ch="$1" cp=0
  if [ -z "$ch" ]; then CHAR_COLS=0; return 0; fi
  if [[ "$ch" == [[:ascii:]] ]]; then CHAR_COLS=1; return 0; fi
  cp="$(printf '%d' "'$ch" 2>/dev/null)" || cp=0
  case "$cp" in ''|*[!0-9]*) cp=0 ;; esac
  if (( cp == 0 )); then
    CHAR_COLS=1
  elif (( cp >= 0x1100 )) && \
       { (( cp <= 0x115F )) || \
         (( cp >= 0x2E80 && cp <= 0x303E )) || \
         (( cp >= 0x3041 && cp <= 0xA4CF )) || \
         (( cp >= 0xAC00 && cp <= 0xD7A3 )) || \
         (( cp >= 0xF900 && cp <= 0xFAFF )) || \
         (( cp >= 0xFE30 && cp <= 0xFE4F )) || \
         (( cp >= 0xFF00 && cp <= 0xFF60 )) || \
         (( cp >= 0xFFE0 && cp <= 0xFFE6 )) || \
         (( cp >= 0x1F000 && cp <= 0x1FAFF )) || \
         (( cp >= 0x2600 && cp <= 0x27BF )); }; then
    CHAR_COLS=2
  else
    CHAR_COLS=1
  fi
  return 0
}

STR_COLS=0
str_cols() { # <text> → STR_COLS
  local s="$1" i
  local n=${#s}
  local total=0
  for ((i = 0; i < n; i++)); do
    char_cols "${s:i:1}"
    total=$(( total + CHAR_COLS ))
  done
  STR_COLS=$total
}

FIT_TEXT=""
fit_text() { # <text> <maxcols> → FIT_TEXT (truncated with …)
  local s="$1" max="${2:-0}" i n
  local total=0 out=""
  FIT_TEXT=""
  (( max <= 0 )) && return 0
  str_cols "$s"
  if (( STR_COLS <= max )); then FIT_TEXT="$s"; return 0; fi
  n=${#s}
  for ((i = 0; i < n; i++)); do
    char_cols "${s:i:1}"
    (( total + CHAR_COLS > max - 1 )) && break
    out+="${s:i:1}"
    total=$(( total + CHAR_COLS ))
  done
  FIT_TEXT="${out}…"
}

PAD=""
pad_for() { # <text> → PAD: spaces that left-pad <text> inside W
  local p
  str_cols "$1"
  p=$(( (W - STR_COLS) / 2 ))
  (( p < 0 )) && p=0
  PAD="$(printf '%*s' "$p" '')"
}

pad_block() { # <blockcols> → PAD: spaces that left-pad a W-wide block
  local p=$(( (W - ${1:-0}) / 2 ))
  (( p < 0 )) && p=0
  PAD="$(printf '%*s' "$p" '')"
}

# ── gradient <text> <r1;g1;b1> <r2;g2;b2> ─────────────────────────
gradient_line() {
  local text="$1" a="${2:-125;207;255}" b="${3:-255;121;198}"
  local ar ag ab br bg bb
  IFS=';' read -r ar ag ab <<< "$a"
  IFS=';' read -r br bg bb <<< "$b"
  local n=${#text} i t r g bl ch
  (( n == 0 )) && return 0
  for ((i = 0; i < n; i++)); do
    if (( n > 1 )); then t=$(( i * 1000 / (n - 1) )); else t=0; fi
    r=$(( ar + (br - ar) * t / 1000 ))
    g=$(( ag + (bg - ag) * t / 1000 ))
    bl=$(( ab + (bb - ab) * t / 1000 ))
    ch="${text:i:1}"
    printf '\033[38;2;%d;%d;%dm%s' "$r" "$g" "$bl" "$ch"
  done
  printf '%s' "$R"
}

info_text() {
  local out model bat
  out="$(date +'%H:%M')"
  if command -v getprop >/dev/null 2>&1; then
    model="$(getprop ro.product.model 2>/dev/null)"
    [ -n "$model" ] && out="${out} · ${model}"
  fi
  if command -v termux-battery-status >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    bat="$(termux-battery-status 2>/dev/null | jq -r '.percentage // empty' 2>/dev/null)"
    [ -n "$bat" ] && out="${out} · ${bat}%"
  fi
  printf '%s · OPX Termux UI %s' "$out" "$OPX_INSTALLED_VERSION"
}

# ── renderers ─────────────────────────────────────────────────────
render_figlet() { # <text> — returns non-zero when figlet cannot fit
  local text="$1" out line maxw=0 left
  command -v figlet >/dev/null 2>&1 || return 1
  out="$(figlet -w "$W" "$text" 2>/dev/null)" || return 1
  [ -n "$out" ] || return 1
  while IFS= read -r line; do
    line="${line%"${line##*[! ]}"}"          # drop figlet's trailing spaces
    [ -z "$line" ] && continue
    str_cols "$line"
    (( STR_COLS > maxw )) && maxw=$STR_COLS
  done <<< "$out"
  (( maxw == 0 )) && return 1
  (( maxw > W )) && return 1
  left=$(( (W - maxw) / 2 ))
  (( left < 0 )) && left=0
  printf '\n'
  while IFS= read -r line; do
    line="${line%"${line##*[! ]}"}"
    [ -z "$line" ] && continue
    printf '%*s' "$left" ''
    gradient_line "$line" '125;207;255' '255;121;198'
    printf '\n'
  done <<< "$out"
  return 0
}

render_boxed() {
  local inner=$(( W - 8 )) rule line_w   # 2-col outer margin, never flush
  (( inner < 16 )) && inner=$(( W - 6 ))
  (( inner < 8 )) && inner=8
  rule="$(printf '─%.0s' $(seq 1 "$inner"))"

  fit_text "$OPX_BANNER_TEXT" "$inner"
  local title="$FIT_TEXT"
  str_cols "$title"; line_w=$STR_COLS

  printf '\n  %s╭%s╮%s\n' "$CY" "$rule" "$R"
  printf '  %s│%s ' "$CY" "$R"
  gradient_line "$title" '125;207;255' '255;121;198'
  printf '%*s' $(( inner - line_w )) ''
  printf ' %s│%s\n' "$CY" "$R"

  if [ -n "$OPX_BANNER_SUB" ]; then
    fit_text "$OPX_BANNER_SUB" "$inner"
    str_cols "$FIT_TEXT"; line_w=$STR_COLS
    local lp=$(( (inner - line_w) / 2 )); (( lp < 0 )) && lp=0
    printf '  %s│%s %s%*s%s%-*s%s %s│%s\n' "$CY" "$R" "$DIM" "$lp" '' \
      "$FIT_TEXT" $(( inner - lp - line_w )) '' "$R" "$CY" "$R"
  fi

  printf '  %s╰%s╯%s\n' "$CY" "$rule" "$R"

  if [ "$OPX_SHOW_INFO" = "1" ] && (( W >= 30 )); then
    fit_text "$(info_text)" $(( W - 4 ))
    printf '  %s%s%s\n' "$MUTE" "$FIT_TEXT" "$R"
  fi
  printf '\n'
}

render_compact() {
  printf '\n'
  fit_text "$OPX_BANNER_TEXT" $(( W - 3 ))
  printf '  '; gradient_line "$FIT_TEXT" '125;207;255' '255;121;198'; printf '\n'
  if [ -n "$OPX_BANNER_SUB" ] && (( W >= 22 )); then
    fit_text "$OPX_BANNER_SUB" $(( W - 3 ))
    printf '  %s%s%s\n' "$DIM" "$FIT_TEXT" "$R"
  fi
  if [ "$OPX_SHOW_INFO" = "1" ] && (( W >= 32 )); then
    fit_text "$(info_text)" $(( W - 3 ))
    printf '  %s%s%s\n' "$MUTE" "$FIT_TEXT" "$R"
  fi
  printf '\n'
}

# ── choose a layout that fits both width and height ────────────────
if (( H < 10 || W < 34 )); then
  render_compact
elif [ "$OPX_BANNER_STYLE" = "2" ]; then
  render_boxed
else
  render_figlet "$OPX_BANNER_TEXT" || render_boxed
fi

fit_text "opx --help  ·  banner · theme · update · doctor" $(( W - 4 ))
if (( W >= 24 )); then
  printf '  %s%s%s\n\n' "$MUTE" "$FIT_TEXT" "$R"
else
  printf '\n'
fi
