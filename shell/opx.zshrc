# ═══════════════════════════════════════════════════════════════════
#  OPX Termux UI — zsh configuration
#  Managed by termux-ui (OPX-official/termux-ui).
#  Personal tweaks belong in ~/.config/opx/config or ~/.zshrc.local
# ═══════════════════════════════════════════════════════════════════

export OPX_HOME="${OPX_HOME:-$HOME/.opx/termux-ui}"
[[ -r "$HOME/.config/opx/config" ]] && source "$HOME/.config/opx/config"

typeset -g OPX_PROMPT_NAME="${OPX_PROMPT_NAME:-opxTeam}"
typeset -g OPX_PROMPT_ICON="${OPX_PROMPT_ICON:-⚡}"
typeset -g OPX_PROMPT_CHAR="${OPX_PROMPT_CHAR:-#}"
typeset -g OPX_VENDOR="$OPX_HOME/vendor"

export PATH="$OPX_HOME/bin:$HOME/.local/bin:$PATH"

# ── history ───────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS \
       SHARE_HISTORY INC_APPEND_HISTORY INTERACTIVE_COMMENTS \
       AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS COMPLETE_IN_WORD NO_BEEP
unsetopt FLOW_CONTROL

# ── completion ────────────────────────────────────────────────────
autoload -Uz compinit && compinit -i -d "$HOME/.zcompdump-$HOST"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{#565f89}── %d ──%f'
zstyle ':completion:*' group-name ''
setopt ALWAYS_TO_END AUTO_MENU LIST_PACKED

# ── key bindings ──────────────────────────────────────────────────
bindkey -e
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ── fish-like suggestions (previous commands appear as ghost text) ─
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=80
if [[ -r "$OPX_VENDOR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$OPX_VENDOR/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# ── fzf: Ctrl-R fuzzy history ─────────────────────────────────────
if (( $+commands[fzf] )); then
  [[ -r "${PREFIX:-}/share/fzf/key-bindings.zsh" ]] && source "${PREFIX}/share/fzf/key-bindings.zsh"
  [[ -r "${PREFIX:-}/share/fzf/completion.zsh"   ]] && source "${PREFIX}/share/fzf/completion.zsh"
  export FZF_DEFAULT_OPTS="--height 45% --reverse --border --info inline \
    --color=fg:#c0caf5,bg:#1a1b26,hl:#7dcfff,fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff,prompt:#7aa2f7,pointer:#ff79c6"
fi

# ── aliases ───────────────────────────────────────────────────────
if (( $+commands[eza] )); then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --group-directories-first --git'
  alias la='eza -la --icons --group-directories-first --git'
  alias lt='eza --tree --level=2 --icons'
else
  alias ls='ls --color=auto'
  alias ll='ls -lh --color=auto'
  alias la='ls -lah --color=auto'
  alias lt='tree -L 2'
fi
(( $+commands[bat] )) && alias cat='bat --paging=never --style=plain'
(( $+commands[bat] )) && alias catp='bat'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias md='mkdir -p'
alias reload='source ~/.zshrc && echo "~/.zshrc reloaded"'
alias update='opx update'
alias banner='opx welcome'
alias cls='clear'

# ── prompt: auto-fits every terminal size ─────────────────────────
OPX_C_BOX='#7dcfff'
OPX_C_ACC='#ffb86c'
OPX_C_PATH='#ff79c6'
OPX_C_CHAR='#50fa7b'
OPX_C_MUTE='#565f89'

# auto (default) · two (always two lines) · one (always one line)
typeset -g OPX_PROMPT_MODE="${OPX_PROMPT_MODE:-auto}"

# shorten <path> <cols> → REPLY; keeps the tail, which is what matters
opx_shorten() {
  local p="$1" m="$2" base
  if (( ${#p} <= m )); then REPLY="$p"; return; fi
  base="${p:t}"
  if (( ${#base} + 2 <= m )); then REPLY="…/${base}"; return; fi
  if (( m <= 1 )); then REPLY=""; return; fi
  REPLY="…${p: -$(( m - 1 ))}"
}

# rebuild PROMPT for the current terminal width
opx_prompt_build() {
  local cols="${COLUMNS:-80}"
  [[ "$cols" == <-> ]] || cols=80
  (( cols < 20 )) && cols=20
  local icon="${OPX_PROMPT_ICON}" name="${OPX_PROMPT_NAME}" ch="${OPX_PROMPT_CHAR}"
  local iw=1; [[ "$icon" == [[:ascii:]] ]] || iw=2
  local mode="${OPX_PROMPT_MODE}"
  if [[ "$mode" != one && "$mode" != two ]]; then
    if (( cols < 32 )); then mode=one; else mode=two; fi
  fi

  local path="${PWD/#$HOME/~}"
  path="${path//\%/%%}"
  ch="${ch//\%/%%}"

  # one spare column in every layout, so the line never sits flush
  # against the right edge (ghost text and typed input then wrap cleanly)
  if [[ "$mode" == one ]]; then
    local avail=$(( cols - iw - ${#name} - 5 ))
    if (( avail < 6 )); then
      # too narrow for the label — keep the path and the char
      opx_shorten "$path" $(( cols - 4 ))
      PROMPT="%F{${OPX_C_PATH}}${REPLY}%f %F{${OPX_C_CHAR}}${ch}%f "
    else
      opx_shorten "$path" "$avail"
      PROMPT="%F{${OPX_C_ACC}}${icon}${name}%f %F{${OPX_C_PATH}}${REPLY}%f %F{${OPX_C_CHAR}}${ch}%f "
    fi
  else
    local avail=$(( cols - 9 - iw - ${#name} ))
    (( avail < 3 )) && avail=3
    opx_shorten "$path" "$avail"
    PROMPT="%F{${OPX_C_BOX}}┌──(%F{${OPX_C_ACC}}${icon}${name}%F{${OPX_C_BOX}})─[%F{${OPX_C_PATH}}${REPLY}%F{${OPX_C_BOX}}]
%F{${OPX_C_BOX}}└─%F{${OPX_C_CHAR}}${ch}%f "
  fi
  PS2="%F{${OPX_C_BOX}}│%f "
  SPROMPT="%F{${OPX_C_PATH}}%R → %r?%f "
}

# ── command timing + right prompt ─────────────────────────────────
autoload -Uz add-zsh-hook
zmodload zsh/datetime 2>/dev/null

opx_preexec() { OPX_CMD_T0=$EPOCHSECONDS; }

opx_precmd() {
  if (( ${+OPX_CMD_T0} )); then
    local dt=$(( EPOCHSECONDS - OPX_CMD_T0 ))
    (( dt >= 6 )) && print -P "%F{${OPX_C_MUTE}}  ⏱ ${dt}s%f"
    unset OPX_CMD_T0
  fi

  opx_prompt_build

  # right prompt only when the terminal is wide enough to hold it
  local cols="${COLUMNS:-80}" br=""
  [[ "$cols" == <-> ]] || cols=80
  if (( cols >= 52 )) && command git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    br=$(command git symbolic-ref --short -q HEAD 2>/dev/null) || \
    br=$(command git rev-parse --short HEAD 2>/dev/null)
    (( ${#br} > 20 )) && br="${br:0:19}…"
    [[ -n "$br" ]] && br=" ${br} "
  fi
  RPROMPT="%F{${OPX_C_MUTE}}${br}%f"
}

# resize → rebuild the prompt immediately instead of waiting for Enter
TRAPWINCH() {
  opx_prompt_build
  # zle is missing in stripped-down builds; never spam the screen for it
  if whence -w zle >/dev/null 2>&1; then
    zle && zle reset-prompt
  fi
}

add-zsh-hook preexec opx_preexec
add-zsh-hook precmd  opx_precmd
setopt TRANSIENT_RPROMPT
opx_prompt_build

# ── syntax highlighting (must be sourced last) ────────────────────
if [[ -r "$OPX_VENDOR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  typeset -A ZSH_HIGHLIGHT_STYLES 2>/dev/null
  ZSH_HIGHLIGHT_STYLES[command]='fg=#9ece6a,bold'
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=#9ece6a'
  ZSH_HIGHLIGHT_STYLES[alias]='fg=#9ece6a,bold'
  ZSH_HIGHLIGHT_STYLES[path]='fg=#7dcfff,underline'
  ZSH_HIGHLIGHT_STYLES[globbing]='fg=#bb9af7'
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f7768e'
  source "$OPX_VENDOR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# ── local extras ──────────────────────────────────────────────────
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
