# dot_claude — installation Makefile
#
# Targets:
#   make install        Link ~/.claude + home files + skill bin scripts (recommended)
#   make install-copy   Copy ~/.claude instead of symlinking (for new machines)
#   make clean          Remove ~/bin symlinks created by skills
#   make help           Show this help
#
# To force overwrite of existing home files:
#   make install FORCE=1

REPO      := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
CLAUDE    := $(REPO).claude
HOME_BIN  := $(HOME)/bin
FORCE     ?= 0

.PHONY: install install-copy _link-claude _copy-claude _home-files _skill-bins clean help

# ── default: symlink mode ──────────────────────────────────────────────────
install: _link-claude _home-files _skill-bins
	@echo ""
	@echo "done — run 'make clean' to remove ~/bin symlinks"

# ── copy mode (new machine without dot_claude already checked out) ─────────
install-copy: _copy-claude _home-files _skill-bins
	@echo ""
	@echo "done (copy mode)"

# ── ~/.claude symlink ──────────────────────────────────────────────────────
_link-claude:
	@if [ -L "$(HOME)/.claude" ]; then \
	  echo "  skip     ~/.claude (already a symlink)"; \
	elif [ -d "$(HOME)/.claude" ]; then \
	  echo "  WARNING  ~/.claude exists as a real directory — skipping."; \
	  echo "           Remove or move it manually, then re-run make install."; \
	else \
	  ln -s "$(CLAUDE)" "$(HOME)/.claude"; \
	  echo "  linked   ~/.claude -> $(CLAUDE)"; \
	fi

# ── ~/.claude copy ─────────────────────────────────────────────────────────
_copy-claude:
	mkdir -p "$(HOME)/.claude"
	cp -r "$(CLAUDE)/." "$(HOME)/.claude"
	@echo "  copied   ~/.claude"

# ── home-level single files ────────────────────────────────────────────────
_home-files:
	@$(MAKE) -f $(lastword $(MAKEFILE_LIST)) _install-file SRC="$(REPO)CLAUDE.md"  DST="$(HOME)/CLAUDE.md"
	@$(MAKE) -f $(lastword $(MAKEFILE_LIST)) _install-file SRC="$(REPO).mcp.json"  DST="$(HOME)/.mcp.json"

_install-file:
	@if [ -e "$(DST)" ] && [ "$(FORCE)" != "1" ]; then \
	  echo "  skip     $(DST) (exists; use FORCE=1 to overwrite)"; \
	else \
	  cp "$(SRC)" "$(DST)"; \
	  echo "  copied   $(DST)"; \
	fi

# ── skill bin scripts (delegate to each skill's Makefile) ─────────────────
_skill-bins:
	@for mk in $(CLAUDE)/skills/*/Makefile; do \
	  skill_dir=$$(dirname "$$mk"); \
	  skill_name=$$(basename "$$skill_dir"); \
	  echo "  skill    $$skill_name"; \
	  $(MAKE) -C "$$skill_dir" install --no-print-directory; \
	done

# ── clean: remove ~/bin symlinks from all skills ──────────────────────────
clean:
	@for mk in $(CLAUDE)/skills/*/Makefile; do \
	  skill_dir=$$(dirname "$$mk"); \
	  skill_name=$$(basename "$$skill_dir"); \
	  echo "  skill    $$skill_name"; \
	  $(MAKE) -C "$$skill_dir" clean --no-print-directory; \
	done
	@echo "done"

# ── help ──────────────────────────────────────────────────────────────────
help:
	@echo "Usage: make [target] [FORCE=1]"
	@echo ""
	@echo "  install       Symlink ~/.claude, copy home files, link skill bins"
	@echo "  install-copy  Same but copy ~/.claude instead of symlinking"
	@echo "  clean         Remove ~/bin symlinks created by skills"
	@echo "  help          Show this message"
	@echo ""
	@echo "  FORCE=1       Overwrite existing home-level files (CLAUDE.md, .mcp.json)"
