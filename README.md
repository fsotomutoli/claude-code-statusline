# Claude Code Status Line

A custom status line script for [Claude Code](https://claude.ai/code) that surfaces useful session info at a glance.

## What it shows

```
🌿 main  |  🟢 14% · 28.4k  |  🟡 57% (114.0k/200.0k)  |  🤖 Sonnet 4.6 [high]  |  🔄 Jun 03 23:20
```

| Segment | Description |
|---|---|
| 🌿 `main` | Current git branch (only shown inside a git repo) |
| 🟢/🟡/🔴 `14% · 28.4k` | Session context window usage % + tokens used |
| 🟢/🟡/🔴 `57% (114.0k/200.0k)` | Global 5-hour rate limit usage % + calculated used/total |
| 🤖 `Sonnet 4.6 [high]` | Active model + effort level |
| 🔄 `Jun 03 23:20` | Next token refresh time |

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
  "statusLine": "bash ~/.claude/statusline.sh"
}
```

If `settings.json` doesn't exist yet, create it with just that content.

**3. Restart Claude Code** — the status line will appear immediately.

## Requirements

- macOS (uses `date -r` for Unix timestamp formatting)
- [`jq`](https://jqlang.github.io/jq/) — install with `brew install jq`
- Claude Code ≥ 2.1
