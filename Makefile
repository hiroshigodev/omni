# OMNI Automation Subsystem
# Provides a unified interface for building, testing, and verifying the Semantic Core.

.PHONY: all build build-wasm test verify clean help help-id

# Default target: Verify everything
all: verify

help:
	@echo "OMNI Command Interface"
	@echo "----------------------"
	@echo "make build       - Build the Wasm core (release mode)"
	@echo "make test        - Run semantic routing verification tests"
	@echo "make verify      - Run build + test to ensure system integrity"
	@echo "make clean       - Remove build artifacts and temporary files"
	@echo "make help-id     - Bahasa Indonesia help"

help-id:
	@echo "Antarmuka Perintah OMNI"
	@echo "-----------------------"
	@echo "make build       - Build Wasm core (mode rilis)"
	@echo "make test        - Jalankan tes verifikasi perutean semantik"
	@echo "make verify      - Jalankan build + test untuk memastikan integritas"
	@echo "make clean       - Hapus artefak build dan file sementara"

# Phase 1: Build Validation
build: build-wasm
	@echo "✓ Build validation successful."

build-wasm:
	@echo "Building OMNI Core (core/zig-out/bin/omni-wasm.wasm)..."
	cd core && zig build -Doptimize=ReleaseSmall
	@if [ -f core/zig-out/bin/omni-wasm.wasm ]; then \
		echo "✓ Wasm binary generated successfully ($(shell du -h core/zig-out/bin/omni-wasm.wasm | cut -f1))"; \
	else \
		echo "✗ Failed to generate Wasm binary"; exit 1; \
	fi

# Phase 2: Functional Testing
test:
	@echo "Running Semantic Core Verification Suite (v2)..."
	@node test-semantic-v2.mjs || { echo "✗ Semantic testing failed"; exit 1; }
	@echo "✓ Semantic routing logic verified."

# Phase 3: Integrity Verification (Build + Test)
verify: build test
	@echo "========================================"
	@echo "🏆 OMNI SYSTEM INTEGRITY: VERIFIED"
	@echo "========================================"

clean:
	@echo "Cleaning artifacts..."
	rm -rf core/zig-out core/.zig-cache
	rm -f omni_config.json.bak
	@echo "✓ Environment cleaned."
