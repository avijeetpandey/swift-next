# =====================================================================
#  SwiftNext — Cross-IDE task orchestration
# ---------------------------------------------------------------------
#  This Makefile is the single source of truth for the developer
#  lifecycle. Both VS Code (.vscode/tasks.json) and Xcode (AppLauncher
#  pre-action scripts) delegate here so behaviour is identical across
#  every editor.
# =====================================================================

SWIFT      ?= swift
PORT       ?= 8080
SCHEME     ?= AppLauncher
SIMULATOR  ?= platform=iOS Simulator,name=iPhone 15

.PHONY: help build run-all run-backend run-frontend run-ios test clean migrate cli

help:
	@echo "SwiftNext targets:"
	@echo "  make build         - Compile every target"
	@echo "  make run-all       - Boot Vapor + AppLauncher concurrently"
	@echo "  make run-backend   - Boot Vapor only (--auto-migrate)"
	@echo "  make run-frontend  - Boot AppLauncher (macOS) only"
	@echo "  make run-ios       - Boot iOS simulator client target"
	@echo "  make test          - Run BackendTests + UIComponentsTests + SharedModelsTests"
	@echo "  make migrate       - Run Fluent migrations"
	@echo "  make cli ARGS=...  - Invoke swiftnext-cli with ARGS"
	@echo "  make clean         - Remove .build artefacts"

build:
	$(SWIFT) build

run-backend:
	$(SWIFT) run SwiftNextServer --auto-migrate

run-frontend:
	$(SWIFT) run AppLauncher

run-ios:
	xcodebuild -scheme $(SCHEME) -destination '$(SIMULATOR)' build

# Concurrent boot. Trap ensures the server is killed when the client exits.
run-all:
	@echo "▶︎  Booting SwiftNext (server + client)…"
	@( $(SWIFT) run SwiftNextServer --auto-migrate & echo $$! > .swiftnext.server.pid ) ; \
	  trap 'kill `cat .swiftnext.server.pid` 2>/dev/null; rm -f .swiftnext.server.pid' EXIT INT TERM ; \
	  sleep 2 ; \
	  $(SWIFT) run AppLauncher

test:
	$(SWIFT) test --parallel

migrate:
	$(SWIFT) run SwiftNextServer migrate --yes

cli:
	$(SWIFT) run swiftnext-cli $(ARGS)

clean:
	$(SWIFT) package clean
	rm -rf .build .swiftnext.server.pid
