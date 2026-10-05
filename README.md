# Claude Code Status Line

A custom status line script for [Claude Code](https://claude.ai/code) that surfaces useful session info at a glance.

## What it shows

```
🌿 main · 💾 2 uncommitted changes  |  🟢 [██░░░░░░░░] 13%  |  🧠 8% ctx  |  🤖 Sonnet 4.6 [high]  |  🔄 Jun 18 03:50 (en 2h 15m)
```

Colors are applied via ANSI: cyan for branch, yellow for uncommitted changes, green/yellow/red for the rate-limit bar and context percentage, magenta for model, blue for refresh time.

| Segment | Description |
|---|---|
| 🌿 `main` | Current git branch (only shown inside a git repo) |
| 💾 `2 uncommitted changes` | Files modified/added/deleted but not yet committed (hidden when clean) |
| 🟢/🟡/🔴 `[██░░░░░░░░] 13%` | Global 5-hour rate limit: progress bar + usage % (claude.ai Pro/Max only) |
| 🧠 `8% ctx` | Share of the model's context window used in the current session |
| 🤖 `Sonnet 4.6 [high]` | Active model + effort level |
| 🔄 `Jun 18 03:50 (en 2h 15m)` | When the 5-hour rate limit resets + relative countdown (claude.ai Pro/Max only) |

**Color coding:**
- 🟢 0–49% — you're good
- 🟡 50–75% — getting there
- 🔴 76–100% — running low

## Installation

**1. Copy the script**

```bash
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/fsotomutoli/claude-code-statusline/main/statusline.sh
chmod +x ~/.claude/statusline.sh
```

**2. Add it to your Claude Code settings**

Open `~/.claude/settings.json` and add:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

If `settings.json` doesn't exist yet, create it with just that content. If it already exists, add the `statusLine` key alongside the existing ones.

**3. Done** — Claude Code reloads settings automatically; restart it if the status line doesn't show up.

## Requirements

- macOS (uses `date -r` for Unix timestamp formatting)
- [`jq`](https://jqlang.github.io/jq/) — install with `brew install jq`
- Claude Code ≥ 2.1

The rate-limit and refresh segments only appear for claude.ai Pro/Max subscribers (Claude Code doesn't send `rate_limits` otherwise). The rest of the line works on any account.
