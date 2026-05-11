#!/usr/bin/env bash
input=$(cat)

dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
branch=""
[ -n "$dir" ] && branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)
branch="${branch:-no-branch}"

tin=$(echo "$input"  | jq -r '.context_window.total_input_tokens  // empty')
tout=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
tokens_seg=""
if [ -n "$tin" ] && [ -n "$tout" ]; then
  total=$(( tin + tout ))
  k=$(( (total + 500) / 1000 ))
  tokens_seg="${k}k tokens"
fi

pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_seg=""
if [ -n "$pct" ]; then
  pct_int=$(printf '%.0f' "$pct")
  ctx_seg="${pct_int}% ctx"
fi

line="$branch"
[ -n "$tokens_seg" ] && line="$line | $tokens_seg"
[ -n "$ctx_seg"    ] && line="$line | $ctx_seg"

printf '%s' "$line"
