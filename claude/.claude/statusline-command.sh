#!/usr/bin/env bash
# Claude Code status line: tokens used, session limit %, context window %.

input=$(cat)

# Pull values out of stdin JSON in one jq call.
read -r in_tok out_tok ctx_pct sess_pct <<<"$(printf '%s' "$input" | jq -r '
  [
    (.context_window.total_input_tokens // 0),
    (.context_window.total_output_tokens // 0),
    (.context_window.used_percentage // -1),
    (.rate_limits.five_hour.used_percentage // -1)
  ] | @tsv
')"

total_tok=$(( ${in_tok:-0} + ${out_tok:-0} ))

# Human-friendly token count.
if [ "$total_tok" -ge 1000000 ]; then
  tokens_str=$(awk "BEGIN { printf \"%.2fM\", $total_tok/1000000 }")
elif [ "$total_tok" -ge 1000 ]; then
  tokens_str=$(awk "BEGIN { printf \"%.1fK\", $total_tok/1000 }")
else
  tokens_str="$total_tok"
fi

# Compose colored output: Tokens: X  Context: X% | Session: X%
# Cyan = tokens, green = context, white = separator, yellow = session.
out=$(printf '\033[36mTokens: %s\033[0m' "$tokens_str")

if [ "$(awk "BEGIN { print (${ctx_pct:--1} >= 0) }")" = "1" ]; then
  out="$out  $(printf '\033[32mContext: %.0f%%\033[0m' "$ctx_pct")"
else
  out="$out  $(printf '\033[32mContext: --\033[0m')"
fi

out="$out$(printf ' \033[0m|\033[0m ')"

if [ "$(awk "BEGIN { print (${sess_pct:--1} >= 0) }")" = "1" ]; then
  out="$out$(printf '\033[33mSession: %.0f%%\033[0m' "$sess_pct")"
else
  out="$out$(printf '\033[33mSession: --\033[0m')"
fi

printf '%s' "$out"