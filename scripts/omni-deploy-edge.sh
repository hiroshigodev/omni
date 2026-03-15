#!/bin/bash
# omni-deploy-edge.sh
# Developer Velocity. Focus on "Build once, run anywhere".

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🚢 OMNI Edge Deployment Preparer${NC}"
echo "════════════════════════════════════════════════"

echo -e "${CYAN}Step 1: Building Native Core...${NC}"
(cd core && zig build-exe src/main.zig --name omni)

echo -e "${CYAN}Step 2: Building WebAssembly Binary (Edge)...${NC}"
(cd core && zig build-exe src/wasm.zig -target wasm32-wasi -O ReleaseSmall -rdynamic --name omni-wasm)

echo -e "${CYAN}Step 3: Building MCP Server...${NC}"
npm run build

echo -e "${CYAN}Step 4: Verifying Wasm Integrity...${NC}"
if [ -f "core/omni-wasm.wasm" ]; then
    size=$(ls -lh core/omni-wasm.wasm | awk '{print $5}')
    echo -e "${GREEN}✅ Wasm Binary Ready: ${size}${NC}"
else
    echo -e "${RED}❌ Wasm Build Failed${NC}"
    exit 1
fi

echo -e "${CYAN}Step 5: Generating OMNI Config...${NC}"
if [ ! -f "core/omni_config.json" ]; then
    echo '{"rules": []}' > core/omni_config.json
    echo "Created default config."
fi

echo -e "\n${GREEN}🚀 OMNI is ready for Edge Deployment!${NC}"
echo "Run 'npm start' to launch the MCP server."
