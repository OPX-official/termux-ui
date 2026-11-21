#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  OPX Termux UI — welcome banner (installed as ~/.termux/motd.sh)
#  Configured by ~/.config/opx/config — never edit this file by hand;
#  run `opx set OPX_BANNER_TEXT "..."` instead.
# ═══════════════════════════════════════════════════════════════════
[ -t 1 ] || exit 0
[ -r "$HOME/.config/opx/config" ] && . "$HOME/.config/opx/config"

: "${OPX_BANNER_TEXT:=OPX TEAM}"
: "${OPX_BANNER_SUB:=Termux UI · by OPX Team}"
: "${OPX_BANNER_STYLE:=1}"
: "${OPX_SHOW_INFO:=1}"
: "${OPX_INSTALLED_VERSION:=1.0.0}"

[ "$OPX_BANNER_STYLE" = "3" ] && exit 0

R=$'\033[0m'; DIM=$'\033[2m'; B=$'\033[1m'
CY=$'\033[38;2;125;207;255m'
MUTE=$'\033[38;2;86;95;137m'
W="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"

# gradient_line <text> <r1;g1;b1> <r2;g2;b2>
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

center_text() { # <text> -> leading spaces
  local t="$1" pad=$(( (W - ${#t}) / 2 ))
  (( pad < 0 )) && pad=0
  printf '%*s' "$pad" ''
}

info_line() {
  local out="" t model bat
  t="$(date +'%H:%M')"
  out="${t}"
  if command -v getprop >/dev/null 2>&1; then
    model="$(getprop ro.product.model 2>/dev/null)"
    [ -n "$model" ] && out="${out}  ·  ${model}"
  fi
  if command -v termux-battery-status >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    bat="$(termux-battery-status 2>/dev/null | jq -r '.percentage // empty' 2>/dev/null)"
    [ -n "$bat" ] && out="${out}  ·  ${bat}%"
  fi
  out="${out}  ·  OPX Termux UI ${OPX_INSTALLED_VERSION}"
  printf '%s%s%s\n' "$MUTE" "$out" "$R"
}

case "$OPX_BANNER_STYLE" in
  1)
    printf '\n'
    if command -v figlet >/dev/null 2>&1; then
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        printf '%s' "$(center_text "$line")"
        gradient_line "$line" '125;207;255' '255;121;198'
        printf '\n'
      done <<< "$(figlet -w "$W" "$OPX_BANNER_TEXT" 2>/dev/null)"
    else
      printf '%s ' "$(center_text "$OPX_BANNER_TEXT")"
      gradient_line "$OPX_BANNER_TEXT" '125;207;255' '255;121;198'
      printf '\n'
    fi
    [ -n "$OPX_BANNER_SUB" ] && printf '%s%s%s%s\n' \
      "$(center_text "$OPX_BANNER_SUB")" "$DIM" "$OPX_BANNER_SUB" "$R"
    [ "$OPX_SHOW_INFO" = "1" ] && printf '  %s\n' "$(info_line)"
    printf '\n'
    ;;
  2)
    inner=$(( W - 6 ))
    (( inner < 24 )) && inner=24
    rule="$(printf '─%.0s' $(seq 1 "$inner"))"
    printf '\n  %s╭%s╮%s\n' "$CY" "$rule" "$R"
    printf '  %s│%s ' "$CY" "$R"
    gradient_line "$OPX_BANNER_TEXT" '125;207;255' '255;121;198'
    printf '%*s' $(( inner - 1 - ${#OPX_BANNER_TEXT} )) ''
    printf '%s│%s\n' "$CY" "$R"
    if [ -n "$OPX_BANNER_SUB" ]; then
      printf '  %s│%s %s%-*s%s %s│%s\n' "$CY" "$R" "$DIM" "$(( inner - 1 ))" \
        "$OPX_BANNER_SUB" "$R" "$CY" "$R"
    fi
    printf '  %s╰%s╯%s\n' "$CY" "$rule" "$R"
    [ "$OPX_SHOW_INFO" = "1" ] && printf '  %s\n' "$(info_line)"
    printf '\n'
    ;;
esac

printf '  %s%s  opx --help%s %sfor banner, theme, update & more%s\n\n' \
  "$MUTE" "" "$R" "$DIM" "$R"
