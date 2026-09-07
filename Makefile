## Makefile for docs.bcdock.io - the BCDock documentation site.
##
## First-run:        make setup && make serve
## Pre-push check:   make build      (mkdocs build --strict)
##
## CI does NOT use this Makefile - it uses actions/setup-python + pip
## directly because GitHub runners ship pip out of the box. This Makefile
## exists for local dev where the system Python may not have python3-venv;
## we use `uv` to sidestep that.

VENV     := .venv
PY       := $(VENV)/bin/python
MKDOCS   := $(VENV)/bin/mkdocs

.PHONY: help setup serve build clean reinstall

help:
	@echo "make setup      - create .venv and install mkdocs-material via uv"
	@echo "make serve      - mkdocs live-reload on http://localhost:8000"
	@echo "make build      - mkdocs build --strict (pre-push gate)"
	@echo "make clean      - remove .venv and built site/"
	@echo "make reinstall  - clean + setup (after requirements.txt changes)"

setup: $(VENV)/bin/mkdocs

$(VENV)/bin/mkdocs: requirements.txt
	@command -v uv >/dev/null || { \
	  echo "ERROR: uv not on PATH. Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"; \
	  exit 1; \
	}
	uv venv --python 3.12 $(VENV)
	uv pip install -p $(VENV) -r requirements.txt
	@echo "OK mkdocs ready: $$($(MKDOCS) --version)"

# Live-reload server. Auto-rebuilds on file change.
serve: setup
	$(MKDOCS) serve --dev-addr 127.0.0.1:8000

# --strict turns warnings (broken links, missing nav refs) into errors.
build: setup
	$(MKDOCS) build --strict

clean:
	rm -rf $(VENV) site/

reinstall: clean setup
