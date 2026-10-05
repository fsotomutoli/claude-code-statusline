#!/bin/bash
input=$(cat)

# Git branch (only when inside a git repo)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
git_branch=""
if [ -n "$cwd" ]; then
  git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
fi

# Global (rate limit) token usage — 5-hour window
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

# Context window usage (% of the model's context window)
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_used=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

# Model and effort
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
effort_level=$(echo "$input" | jq -r '.effort.level // empty')

# Format raw token counts as e.g. 12.3k or 200.0k
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

# Returns ANSI color for a percentage (green/yellow/red)
pct_color() {
  local pct=$1
  if [ "$pct" -le 49 ]; then
    echo $'\033[32m'
  elif [ "$pct" -le 75 ]; then
    echo $'\033[33m'
  else
    echo $'\033[31m'
  fi
}

# Build a 10-segment ANSI-colored progress bar, e.g. [████░░░░░░]
progress_bar() {
  local pct=$1
  local filled=$(awk "BEGIN {n=int($pct/10); if(n>10) n=10; print n}")
  local empty=$((10 - filled))
  local color reset
  color=$(pct_color "$pct")
  reset=$'\033[0m'
  local bar="[${color}"
  local i
  for ((i=0; i<filled; i++)); do bar="${bar}█"; done
  bar="${bar}${reset}"
  for ((i=0; i<empty; i++)); do bar="${bar}░"; done
  bar="${bar}]"
  echo "$bar"
}

# Arcade style colors
C_CYAN=$'\033[96m'
C_YELLOW=$'\033[93m'
C_MAGENTA=$'\033[95m'
C_BLUE=$'\033[94m'
C_GRAY=$'\033[90m'
C_BLUE_DIM=$'\033[34m'
C_DIM=$'\033[2m'
C_RESET=$'\033[0m'

SEP="${C_DIM}  |  ${C_RESET}"

parts=""

# 1. 🌿 Git branch + uncommitted changes count
if [ -n "$git_branch" ]; then
  parts="🌿 ${C_CYAN}${git_branch}${C_RESET}"
  if [ -n "$cwd" ]; then
    uncommitted=$(git -C "$cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$uncommitted" -gt 0 ] 2>/dev/null; then
      parts="${parts} · 💾 ${C_YELLOW}${uncommitted} uncommitted changes${C_RESET}"
    fi
  fi
fi

# 2. Global (5-hour rate limit): colored dot + progress bar + %
if [ -n "$five_pct" ]; then
  five_int=$(printf '%.0f' "$five_pct")
  dot=$(color_dot "$five_int")
  bar=$(progress_bar "$five_int")
  pct_col=$(pct_color "$five_int")
  [ -n "$parts" ] && parts="${parts}${SEP}"
  parts="${parts}${dot} ${bar} ${pct_col}${five_int}%${C_RESET}"
fi

# 3. 🧠 Context window usage: % + tokens in context / window size
if [ -n "$ctx_pct" ]; then
  ctx_int=$(printf '%.0f' "$ctx_pct")
  ctx_col=$(pct_color "$ctx_int")
  ctx_detail=""
  used_fmt=$(fmt_tokens "$ctx_used")
  size_fmt=$(fmt_tokens "$ctx_size")
  [ -n "$used_fmt" ] && [ -n "$size_fmt" ] && ctx_detail="${C_DIM} (${used_fmt}/${size_fmt})${C_RESET}"
  [ -n "$parts" ] && parts="${parts}${SEP}"
  parts="${parts}🧠 ${ctx_col}${ctx_int}%${C_RESET}${C_DIM} ctx${C_RESET}${ctx_detail}"
fi

# 4. 🤖 Model name + effort level
if [ -n "$model_name" ]; then
  [ -n "$parts" ] && parts="${parts}${SEP}"
  model_str="$model_name"
  if [ -n "$effort_level" ]; then
    model_str="${model_str} [${effort_level}]"
  fi
  parts="${parts}🤖 ${C_MAGENTA}${model_str}${C_RESET}"
fi

# 5. 🔄 Next token refresh time (Unix timestamp -> human readable + relative)
if [ -n "$five_reset" ] && [ "$five_reset" -gt 0 ] 2>/dev/null; then
  reset_fmt=$(date -r "$five_reset" "+%b %d %H:%M" 2>/dev/null)
  if [ -n "$reset_fmt" ]; then
    now=$(date +%s)
    diff=$(( five_reset - now ))
    if [ "$diff" -gt 0 ]; then
      hours=$(( diff / 3600 ))
      mins=$(( (diff % 3600) / 60 ))
      if [ "$hours" -gt 0 ]; then
        relative="en ${hours}h ${mins}m"
      else
        relative="en ${mins}m"
      fi
      reset_fmt="${reset_fmt} ${C_BLUE_DIM}(${relative})${C_RESET}"
    fi
    [ -n "$parts" ] && parts="${parts}${SEP}"
    parts="${parts}🔄 ${C_BLUE}${reset_fmt}${C_RESET}"
  fi
fi

echo "$parts"
