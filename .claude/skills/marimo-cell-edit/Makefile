# marimo-cell-edit skill — install / clean
#
# make install   Create symlinks in ~/bin/ → scripts/
# make clean     Remove those symlinks

SKILL_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SCRIPTS   := $(SKILL_DIR)scripts
BIN       := $(HOME)/bin

BINS := marimo-serve marimo-cell-edit

.PHONY: install clean

install:
	mkdir -p $(BIN)
	@for b in $(BINS); do \
	  chmod +x $(SCRIPTS)/$$b; \
	  ln -sf $(SCRIPTS)/$$b $(BIN)/$$b; \
	  echo "  linked   $(BIN)/$$b -> $(SCRIPTS)/$$b"; \
	done
	@echo "done — add $(BIN) to PATH if not already present"

clean:
	@for b in $(BINS); do \
	  if [ -L $(BIN)/$$b ]; then \
	    rm -f $(BIN)/$$b; \
	    echo "  removed  $(BIN)/$$b"; \
	  else \
	    echo "  skip     $(BIN)/$$b (not a symlink)"; \
	  fi; \
	done
	@echo "done"
