# dot_claude

Personal Claude Code configuration.

## Structure

```
dot_claude/
├── CLAUDE.md                          → ~/CLAUDE.md           (global instructions)
├── .mcp.json                          → ~/.mcp.json            (MCP server definitions)
├── install.sh                         (deploy script)
└── .claude/
    ├── settings.json                  → ~/.claude/settings.json
    │                                    (permissions, hooks, auto-approval, plugins)
    ├── keybindings.json               → ~/.claude/keybindings.json
    ├── hooks/                         → ~/.claude/hooks/
    │   └── (custom hook scripts)
    ├── plugins/
    │   └── known_marketplaces.json    → ~/.claude/plugins/known_marketplaces.json
    └── skills/
        ├── deligate-sudo-to-user/     Delegate sudo ops to user
        ├── gemini-search/             Web search via Gemini CLI
        ├── perplexity-research/       Multi-source web research (Perplexity-style)
        ├── wiki-read/                 Read Wiki.js pages
        ├── wiki-search/               Search Wiki.js
        └── wiki-update/               Create/update Wiki.js pages
```

## Install

```bash
git clone git@github.com:kmitsutani/dot_claude.git
cd dot_claude
./install.sh
```

Options:

| Flag | Effect |
|------|--------|
| *(none)* | Copy files to `~/.claude/` |
| `--link` | Symlink `skills/` and `hooks/` dirs (repo updates apply immediately) |
| `--dry-run` | Preview without making changes |

> **Note:** `settings.json` is skipped if it already exists — merge manually.

## Hooks

Place executable scripts in `.claude/hooks/`. Reference them in `settings.json`:

```json
{
  "hooks": {
    "Stop": [{ "type": "command", "command": "bash ~/.claude/hooks/on-stop.sh" }],
    "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/pre-bash.sh" }] }]
  }
}
```

## MCP Servers

Edit `.mcp.json` to add MCP server definitions:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["-y", "@my-org/mcp-server"]
    }
  }
}
```
