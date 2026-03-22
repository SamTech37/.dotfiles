# autojump
[ -f /usr/share/autojump/autojump.sh ] && . /usr/share/autojump/autojump.sh

# cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# fnm
# Prefer existing PATH, otherwise discover the default install location.
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --shell bash)"
else
  if [ -d "$HOME/.fnm" ]; then
    FNM_PATH="$HOME/.fnm"
  elif [ -n "${XDG_DATA_HOME:-}" ]; then
    FNM_PATH="$XDG_DATA_HOME/fnm"
  elif [ "$(uname -s)" = "Darwin" ]; then
    FNM_PATH="$HOME/Library/Application Support/fnm"
  else
    FNM_PATH="$HOME/.local/share/fnm"
  fi

  if [ -x "$FNM_PATH/fnm" ]; then
    export PATH="$FNM_PATH:$PATH"
    eval "$(fnm env --shell bash)"
  fi

  unset FNM_PATH
fi
