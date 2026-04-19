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

echo "Installing dot_claude to ${CLAUDE_DIR} (mode: ${MODE})"
$DRY_RUN && echo "(dry-run mode — no changes will be made)"

mkdir -p "${CLAUDE_DIR}"

# skills
if [[ "$MODE" == "link" ]]; then
  if [[ -d "${CLAUDE_DIR}/skills" && ! -L "${CLAUDE_DIR}/skills" ]]; then
    echo "WARNING: ${CLAUDE_DIR}/skills exists and is not a symlink. Skipping to avoid data loss."
    echo "         Remove or rename it manually, then re-run."
  else
    run ln -sfn "${REPO_DIR}/.claude/skills" "${CLAUDE_DIR}/skills"
    echo "Linked: ${CLAUDE_DIR}/skills -> ${REPO_DIR}/.claude/skills"
  fi
else
  run cp -r "${REPO_DIR}/.claude/skills" "${CLAUDE_DIR}/"
  echo "Copied: ${CLAUDE_DIR}/skills"
fi

# settings.json — merge if exists, copy if not
SETTINGS_SRC="${REPO_DIR}/.claude/settings.json"
SETTINGS_DST="${CLAUDE_DIR}/settings.json"

if [[ -f "${SETTINGS_DST}" ]]; then
  echo "WARNING: ${SETTINGS_DST} already exists. Skipping to avoid overwrite."
  echo "         Merge manually from: ${SETTINGS_SRC}"
else
  run cp "${SETTINGS_SRC}" "${SETTINGS_DST}"
  echo "Copied: ${SETTINGS_DST}"
fi

echo ""
echo "Done."
