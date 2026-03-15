# CLAUDE.md

This file provides guidance to Claude Code when working in the **OMNI** repository.

## Project Overview
**OMNI** (Optimization Middleware & Next-gen Interface) is a hybrid token-efficiency platform using a Zig core (for Wasm/performance) and a TypeScript MCP server (for integration).

## Development Commands

## Development Commands

### Core (Zig)
- `zig build-exe core/src/main.zig --name omni` - Build native engine
- `zig build-exe core/src/wasm.zig -target wasm32-wasi -O ReleaseSmall -rdynamic --name omni-wasm` - Build Wasm core
- `zig test core/src/main.zig` - Run core tests
- `zig fmt core/src/` - Format Zig code

### MCP Interface (TypeScript)
- `npm install` - Install dependencies
- `npm run build` - Compile TypeScript
- `npm start` - Start the MCP server

### Utility Scripts
- `./scripts/omni-deploy-edge.sh` - Unified build and deploy
- `./scripts/omni-report.sh` - Unified system metrics and status
- `./scripts/omni-distill-pro.sh` - Semantic distillation demo

## Directory Structure
- `core/` - Zig engine core & filters
- `src/` - MCP server implementation & LRU cache
- `docs/` - Project documentation
- `scripts/` - Automation, benchmark, and reporting scripts

## Design Principles
1. **Efficiency:** Minimal startup time (<1ms via Wasm & LRU cache). 
2. **Modularity:** Plugin-based filter architecture.
3. **Semantic First:** Prioritize signal over mere truncation.
4. **Local-First:** All processing data stays on the user's machine.

## Workflow Patterns
- **Zig First:** Implement core logic in `core/` with high test coverage.
- **Wasm Target:** Always verify that core logic compiles for `wasm32-wasi`.
- **MCP Standards:** Follow the Model Context Protocol strictly for tool definitions.
