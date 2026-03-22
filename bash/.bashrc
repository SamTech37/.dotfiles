# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# source modular bash config files
# set BASH_DEBUG=1 to enable debug output
BASH_DEBUG=${BASH_DEBUG:-0}

if [ -d ~/.config/bash ]; then
    _bash_all_ok=1
    for f in ~/.config/bash/*.sh; do
        if [ -f "$f" ]; then
            if . "$f" 2>/tmp/bash_module_err; then
                [ "$BASH_DEBUG" = "1" ] && echo "[bash] loaded: $f"
            else
                _bash_all_ok=0
                echo "[bash] ERROR loading: $f — $(cat /tmp/bash_module_err)"
            fi
        fi
    done
    [ "$_bash_all_ok" = "1" ] && [ "$BASH_DEBUG" = "0" ] && echo "[bash] all modules loaded"
    unset _bash_all_ok
fi
