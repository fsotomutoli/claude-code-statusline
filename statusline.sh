#!/bin/bash
input=$(cat)

# Git branch (only when inside a git repo)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
git_branch=""
if [ -n "$cwd" ]; then
  git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
fi

# Session (context window) token usage
ctx_used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')

# Global (rate limit) token usage — 5-hour window
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
ctx_window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

# Model and effort
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
effort_level=$(echo "$input" | jq -r '.effort.level // empty')

# Format raw token counts as e.g. 12.3k or 200k
fmt_tokens() {
  local n=$1
  if [ -n "$n" ] && [ "$n" -gt 0 ] 2>/dev/null; then
    if [ "$n" -ge 1000 ]; then
      awk "BEGIN {printf \"%.1fk\", $n/1000}"
    else
      echo "$n"
    fi
  fi
}

# Return colored circle emoji based on percentage (0-49 green, 50-75 yellow, 76-100 red)
color_dot() {
  local pct=$1
  if [ "$pct" -le 49 ]; then
    echo "🟢"
  elif [ "$pct" -le 75 ]; then
    echo "🟡"
  else
    echo "🔴"
  fi
}

parts=""

# 1. 🌿 Git branch
if [ -n "$git_branch" ]; then
  parts="🌿 ${git_branch}"
fi

# 2. Session: colored dot + % + raw tokens used
if [ -n "$ctx_used_pct" ]; then
  ctx_int=$(printf '%.0f' "$ctx_used_pct")
  dot=$(color_dot "$ctx_int")
  raw=$(fmt_tokens "$ctx_input_tokens")
  detail=""
  if [ -n "$raw" ]; then
    detail=" · ${raw}"
  fi
  [ -n "$parts" ] && parts="$parts  |  "
  parts="${parts}${dot} ${ctx_int}%${detail}"
fi

# 3. Global (5-hour): colored dot + % + calculated used/total from context window size
if [ -n "$five_pct" ]; then
  five_int=$(printf '%.0f' "$five_pct")
  dot=$(color_dot "$five_int")
  detail=""
  if [ -n "$ctx_window_size" ] && [ "$ctx_window_size" -gt 0 ] 2>/dev/null; then
    five_used_calc=$(awk "BEGIN {printf \"%d\", $five_pct * $ctx_window_size / 100}")
    used_fmt=$(fmt_tokens "$five_used_calc")
    total_fmt=$(fmt_tokens "$ctx_window_size")
    [ -n "$used_fmt" ] && [ -n "$total_fmt" ] && detail=" (${used_fmt}/${total_fmt})"
  fi
  [ -n "$parts" ] && parts="$parts  |  "
  parts="${parts}${dot} ${five_int}%${detail}"
fi

# 4. 🤖 Model name + effort level
if [ -n "$model_name" ]; then
  [ -n "$parts" ] && parts="$parts  |  "
  model_str="$model_name"
  if [ -n "$effort_level" ]; then
    model_str="${model_str} [${effort_level}]"
  fi
  parts="${parts}🤖 ${model_str}"
fi

# 5. 🔄 Next token refresh time (Unix timestamp -> human readable)
if [ -n "$five_reset" ] && [ "$five_reset" -gt 0 ] 2>/dev/null; then
  reset_fmt=$(date -r "$five_reset" "+%b %d %H:%M" 2>/dev/null)
  if [ -n "$reset_fmt" ]; then
    [ -n "$parts" ] && parts="$parts  |  "
    parts="${parts}🔄 ${reset_fmt}"
  fi
fi

echo "$parts"
