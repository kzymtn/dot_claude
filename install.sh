#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

usage() {
  echo "Usage: $0 [--copy | --link] [--dry-run]"
  echo ""
  echo "  --copy     Copy files (default)"
  echo "  --link     Symlink directories instead of copying"
  echo "  --dry-run  Show what would happen without making changes"
  exit 1
}

MODE="copy"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --copy)    MODE="copy" ;;
    --link)    MODE="link" ;;
    --dry-run) DRY_RUN=true ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $arg"; usage ;;
  esac
done

run() {
  if $DRY_RUN; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

# Copy a single file; skip with warning if destination already exists
copy_file() {
  local src="$1" dst="$2"
  if [[ -f "$dst" ]]; then
    echo "WARNING: ${dst} already exists. Skipping."
    echo "         Merge manually from: ${src}"
  else
    run cp "$src" "$dst"
    echo "Copied:  ${dst}"
  fi
}

# Install a directory — symlink or copy
install_dir() {
  local name="$1"
  local src="${REPO_DIR}/.claude/${name}"
  local dst="${CLAUDE_DIR}/${name}"

  [[ -d "$src" ]] || return 0

  if [[ "$MODE" == "link" ]]; then
    if [[ -d "$dst" && ! -L "$dst" ]]; then
      echo "WARNING: ${dst} exists and is not a symlink. Skipping to avoid data loss."
      echo "         Remove or rename it manually, then re-run."
    else
      run ln -sfn "$src" "$dst"
      echo "Linked:  ${dst} -> ${src}"
    fi
  else
    run cp -r "$src" "$dst"
    echo "Copied:  ${dst}"
  fi
}

echo "Installing dot_claude → ${CLAUDE_DIR} (mode: ${MODE})"
$DRY_RUN && echo "(dry-run mode — no changes will be made)"
echo ""

run mkdir -p "${CLAUDE_DIR}"
run mkdir -p "${CLAUDE_DIR}/hooks"
run mkdir -p "${CLAUDE_DIR}/plugins"

# ── Directories ────────────────────────────────────────────────
install_dir skills
install_dir hooks

# ── Single files ───────────────────────────────────────────────
copy_file "${REPO_DIR}/.claude/settings.json"             "${CLAUDE_DIR}/settings.json"
copy_file "${REPO_DIR}/.claude/keybindings.json"          "${CLAUDE_DIR}/keybindings.json"
copy_file "${REPO_DIR}/.claude/plugins/known_marketplaces.json" \
                                                          "${CLAUDE_DIR}/plugins/known_marketplaces.json"

# ── Home-level files ───────────────────────────────────────────
copy_file "${REPO_DIR}/CLAUDE.md"  "${HOME}/CLAUDE.md"
copy_file "${REPO_DIR}/.mcp.json"  "${HOME}/.mcp.json"

echo ""
echo "Done."
