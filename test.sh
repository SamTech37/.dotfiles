#!/bin/bash
# Dotfiles validation suite — run from any directory.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0
WARN=0

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; NC='\033[0m'

pass() { printf "  ${GREEN}✓${NC} %s\n" "$1"; PASS=$((PASS+1)); }
fail() { printf "  ${RED}✗${NC} %s\n" "$1"; FAIL=$((FAIL+1)); }
warn() { printf "  ${YELLOW}~${NC} %s\n" "$1"; WARN=$((WARN+1)); }
section() { printf "\n${BOLD}%s${NC}\n" "$1"; }

# ── Helpers ───────────────────────────────────────────────────────────────────

# Parse STOW_DIRS array from setup.sh so this file stays in sync automatically.
mapfile -t STOW_DIRS < <(
    awk '/^STOW_DIRS=\(/{f=1;next} f&&/^\)/{f=0} f{gsub(/^[[:space:]]+|[[:space:]]+$|#.*/,""); if($0!="") print}' \
        "$SCRIPT_DIR/setup.sh"
)

# Resolve symlink target, stripping stow's relative indirection.
symlink_target() { readlink -f "$1" 2>/dev/null || true; }

# ── 1. Stow symlinks ──────────────────────────────────────────────────────────
section "1. Stow symlinks"

for pkg in "${STOW_DIRS[@]}"; do
    pkg_dir="$SCRIPT_DIR/$pkg"
    if [ ! -d "$pkg_dir" ]; then
        fail "$pkg: package directory missing in repo"
        continue
    fi

    while IFS= read -r -d '' src; do
        rel="${src#"$pkg_dir"/}"
        target="$HOME/$rel"

        if [ -L "$target" ]; then
            real=$(symlink_target "$target")
            if [ "$real" = "$src" ]; then
                pass "$pkg: $rel"
            else
                fail "$pkg: $rel → wrong target ($real)"
            fi
        elif [ -e "$target" ]; then
            fail "$pkg: $rel → real file in \$HOME (not a symlink — stow not run?)"
        else
            fail "$pkg: $rel → missing from \$HOME"
        fi
    done < <(find "$pkg_dir" -type f -print0)
done

# ── 2. Syntax checks ──────────────────────────────────────────────────────────
section "2. Config syntax"

while IFS= read -r -d '' f; do
    rel="${f#"$SCRIPT_DIR"/}"
    err=$(bash -n "$f" 2>&1) && pass "sh: $rel" || fail "sh: $rel — $err"
done < <(find "$SCRIPT_DIR" -not -path '*/.git/*' -name '*.sh' -print0)

while IFS= read -r -d '' f; do
    rel="${f#"$SCRIPT_DIR"/}"
    err=$(jq empty "$f" 2>&1) && pass "json: $rel" || fail "json: $rel — $err"
done < <(find "$SCRIPT_DIR" -not -path '*/.git/*' -name '*.json' -print0)

while IFS= read -r -d '' f; do
    rel="${f#"$SCRIPT_DIR"/}"
    err=$(python3 -m py_compile "$f" 2>&1) && pass "py: $rel" || fail "py: $rel — $err"
done < <(find "$SCRIPT_DIR" -not -path '*/.git/*' -name '*.py' -print0)

# ── 3. Bash modules load cleanly ──────────────────────────────────────────────
section "3. Bash modules"

for f in "$HOME/.config/bash/"*.sh; do
    [ -f "$f" ] || continue
    rel="${f#"$HOME"/}"

    err=$(bash -n "$f" 2>&1) || { fail "syntax: $rel — $err"; continue; }
    pass "syntax: $rel"

    # Source in an isolated subshell so failures don't affect us.
    if (set +e; source "$f" >/dev/null 2>&1); then
        pass "sources: $rel"
    else
        warn "sources: $rel — errors on source (tool may not be installed)"
    fi
done

# ── 4. Required tools ─────────────────────────────────────────────────────────
section "4. Required tools"

# Core tools from setup.sh + independent installers.
REQUIRED_TOOLS=(git curl tmux stow jq python3 cargo starship lazygit rtk)
OPTIONAL_TOOLS=(fnm tldr vlc flatpak btop autojump)

for tool in "${REQUIRED_TOOLS[@]}"; do
    command -v "$tool" &>/dev/null \
        && pass "$tool ($(command -v "$tool"))" \
        || fail "$tool — not found in PATH"
done

for tool in "${OPTIONAL_TOOLS[@]}"; do
    command -v "$tool" &>/dev/null \
        && pass "$tool (optional, present)" \
        || warn "$tool — not found (optional)"
done

# ── 5. Claude config ──────────────────────────────────────────────────────────
section "5. Claude config"

settings="$HOME/.claude/settings.json"
if [ -f "$settings" ]; then
    jq empty "$settings" 2>/dev/null \
        && pass "settings.json is valid JSON" \
        || fail "settings.json is invalid JSON"
    jq -e '.hooks.PreToolUse' "$settings" >/dev/null 2>&1 \
        && pass "settings.json: RTK hook present" \
        || warn "settings.json: no PreToolUse hooks found"
else
    fail "settings.json missing from ~/.claude/"
fi

statusline="$HOME/.claude/statusline-command.sh"
[ -f "$statusline" ]    && pass "statusline-command.sh present" || fail "statusline-command.sh missing"
[ -x "$statusline" ]    && pass "statusline-command.sh is executable" \
                         || warn "statusline-command.sh is not executable"

# ── Summary ───────────────────────────────────────────────────────────────────
TOTAL=$((PASS + FAIL + WARN))
printf "\n${BOLD}Results: ${GREEN}%d passed${NC}" "$PASS"
[ "$WARN" -gt 0 ] && printf ", ${YELLOW}%d warned${NC}" "$WARN"
[ "$FAIL" -gt 0 ] && printf ", ${RED}%d failed${NC}" "$FAIL"
printf " / %d total\n\n" "$TOTAL"

[ "$FAIL" -eq 0 ]
