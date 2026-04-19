# dot_claude

Personal Claude Code configuration — skills and settings.

## Structure

```
.claude/
  skills/
    deligate-sudo-to-user/   # Delegate sudo operations to user
    gemini-search/           # Web search via Gemini CLI
    perplexity-research/     # Multi-source web research (Perplexity-style)
    wiki-read/               # Read Wiki.js pages
    wiki-search/             # Search Wiki.js
    wiki-update/             # Create/update Wiki.js pages
  settings.json              # Claude Code settings (auto-approval rules, plugins)
```

## Install

Symlink or copy `.claude/` to `~/.claude/`.

```bash
# symlink skills
ln -s $(pwd)/.claude/skills ~/.claude/skills
```
