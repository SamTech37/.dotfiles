#!/usr/bin/env bash
# Claude Code status line: tokens used, context window %, session limit %, weekly limit %.

input=$(cat)
now=$(date +%s)

# Pull all six fields from stdin JSON in one jq call.
# Fields: in_tok out_tok ctx_pct sess_pct sess_resets week_pct week_resets
read -r in_tok out_tok ctx_pct sess_pct sess_resets week_pct week_resets <<<"$(printf '%s' "$input" | jq -r '
  [
    (.context_window.total_input_tokens // 0),
    (.context_window.total_output_tokens // 0),
    (.context_window.used_percentage // -1),
    (.rate_limits.five_hour.used_percentage // -1),
    (.rate_limits.five_hour.resets_at // -1),
    (.rate_limits.seven_day.used_percentage // -1),
    (.rate_limits.seven_day.resets_at // -1)
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

# Format a seconds-delta as a compact countdown: ?h?m or ?d?h?m (zero units kept for stable width).
# Usage: fmt_countdown <seconds_delta>
fmt_countdown() {
  local secs=$(( $1 < 0 ? 0 : $1 ))
  local days=$(( secs / 86400 ))
  local hours=$(( (secs % 86400) / 3600 ))
  local mins=$(( (secs % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then
    printf '%dd%dh%dm' "$days" "$hours" "$mins"
  else
    printf '%dh%dm' "$hours" "$mins"
  fi
}

# Compose colored output: Tokens: X  Context: X% | Session X% (?h?m)  Weekly X% (?d?h?m)
# Cyan = tokens, green = context, yellow = session, magenta = weekly.
out=$(printf '\033[36mTokens: %s\033[0m' "$tokens_str")

if [ "$(awk "BEGIN { print (${ctx_pct:--1} >= 0) }")" = "1" ]; then
  out="$out  $(printf '\033[32mContext: %.0f%%\033[0m' "$ctx_pct")"
else
  out="$out  $(printf '\033[32mContext: --\033[0m')"
fi

out="$out$(printf ' \033[0m|\033[0m ')"

# Session segment (5-hour limit).
if [ "$(awk "BEGIN { print (${sess_pct:--1} >= 0) }")" = "1" ]; then
  sess_label=$(printf '%.0f%%' "$sess_pct")
  if [ "$(awk "BEGIN { print (${sess_resets:--1} >= 0) }")" = "1" ]; then
    sess_delta=$(( ${sess_resets%.*} - now ))
    sess_label="$sess_label ($(fmt_countdown "$sess_delta"))"
  fi
  out="$out$(printf '\033[33mSession %s\033[0m' "$sess_label")"
else
  out="$out$(printf '\033[33mSession --\033[0m')"
fi

# Weekly segment (7-day limit).
if [ "$(awk "BEGIN { print (${week_pct:--1} >= 0) }")" = "1" ]; then
  week_label=$(printf '%.0f%%' "$week_pct")
  if [ "$(awk "BEGIN { print (${week_resets:--1} >= 0) }")" = "1" ]; then
    week_delta=$(( ${week_resets%.*} - now ))
    week_label="$week_label ($(fmt_countdown "$week_delta"))"
  fi
  out="$out$(printf '  \033[35mWeekly %s\033[0m' "$week_label")"
fi

printf '%s' "$out"
