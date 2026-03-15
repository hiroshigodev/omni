#!/bin/sh
# OMNI Installer - Semantic Distillation Engine
# https://github.com/fajarhide/omni
# Usage: curl -fsSL https://raw.githubusercontent.com/fajarhide/omni/main/install.sh | sh

set -e

REPO="fajarhide/omni"
INSTALL_DIR="${OMNI_INSTALL_DIR:-$HOME/omni}"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; exit 1; }

echo "${BLUE}🌌 Welcome to the OMNI Installer${NC}"
echo "════════════════════════════════════════════"

# 1. Dependency Check
info "Checking dependencies..."
if ! command -v zig >/dev/null 2>&1; then
    error "Zig 0.15.2+ is required. Please install it from ziglang.org."
fi

if ! command -v node >/dev/null 2>&1; then
    error "Node.js 18+ is required. Please install it from nodejs.org."
fi

if ! command -v git >/dev/null 2>&1; then
    error "Git is required to clone the repository."
fi

# 2. Clone
if [ -d "$INSTALL_DIR" ]; then
    warn "Directory $INSTALL_DIR already exists. Updating..."
    cd "$INSTALL_DIR" && git pull
else
    info "Cloning OMNI to $INSTALL_DIR..."
    git clone "https://github.com/${REPO}.git" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# 3. Build
info "Building OMNI Core and Edge binaries..."
sh ./scripts/omni-deploy-edge.sh

# 4. Success & Instructions
echo ""
echo "${GREEN}✅ OMNI successfully installed in $INSTALL_DIR${NC}"
echo "════════════════════════════════════════════"
info "To integrate with Claude Code / Antigravity, add this to your MCP config:"
echo ""
echo "${YELLOW}{"
echo "  \"mcpServers\": {"
echo "    \"omni\": {"
echo "      \"command\": \"node\","
echo "      \"args\": [\"$INSTALL_DIR/dist/index.js\"]"
echo "    }"
echo "  }"
echo "}${NC}"
echo ""
info "Run './scripts/omni-report.sh' inside $INSTALL_DIR to verify."
