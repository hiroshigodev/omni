# OMNI Development Guide

Welcome to the Project OMNI development guide.

## Contribution Workflow

1.  **Core Development**: Core logic is implemented in Zig for performance and portability.
2.  **Testing**: Always include tests for new filters and engine modifications.
3.  **MCP Integration**: Ensure compatibility with the Model Context Protocol.

## Getting Started

To set up your environment:
- Install [Zig 0.15.2+](https://ziglang.org/).
- Install [Node.js 18+](https://nodejs.org/).
- Clone the repository and run `npm install`.

## Building OMNI

```bash
zig build        # Build native & wasm engine
npm run build    # Compile MCP gateway
```

For detailed internal architecture and proprietary release workflows, please consult the internal team documentation.
