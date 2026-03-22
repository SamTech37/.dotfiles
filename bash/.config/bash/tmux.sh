# tmux startup policy:
# - Terminal at $HOME: attach to session "main"
# - Terminal in specific directory (e.g. Nautilus "Open in Terminal"): create a new window at $PWD and attach
if command -v tmux >/dev/null 2>&1 && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  TMUX_SESSION="main"
  tmux has-session -t "$TMUX_SESSION" 2>/dev/null || tmux new-session -d -s "$TMUX_SESSION" -c "$HOME"

  if [[ "$PWD" != "$HOME" ]]; then
    tmux new-window -t "$TMUX_SESSION" -c "$PWD" >/dev/null 2>&1 || true
    exec tmux attach -t "$TMUX_SESSION"
  else
    exec tmux new-session -A -s "$TMUX_SESSION"
  fi
fi
