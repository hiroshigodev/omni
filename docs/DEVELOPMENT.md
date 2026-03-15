# OMNI Development Guide 🛠

Welcome to the Project OMNI development guide. This document outlines how to maintain the core engine and expand its semantic filtering capabilities.

## 🏗 Architecture Overview

OMNI consists of two main components:
1.  **Zig Core**: The high-performance compression engine, compiled to both native and WebAssembly.
2.  **TypeScript Host**: The MCP server that orchestrates Wasm execution and provides an LRU caching layer.

## 🌈 Adding a New Filter

To add a new semantic filter:

1.  **Create a Filter Module**: Add a new `.zig` file in `core/src/filters/`.
    ```zig
    const std = @import("std");
    const Filter = @import("interface.zig").Filter;

    pub const MyNewFilter = struct {
        pub fn filter() Filter {
            return .{
                .name = "my_filter",
                .ptr = undefined,
                .matchFn = match,
                .processFn = process,
            };
        }

        fn match(_: *anyopaque, input: []const u8) bool {
            return std.mem.indexOf(u8, input, "keyword") != null;
        }

        fn process(_: *anyopaque, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
            // Your logic here
            return try allocator.dupe(u8, "summarized output");
        }
    };
    ```

2.  **Register the Filter**:
    - Add the import and register in `core/src/main.zig` (for native).
    - Add the import and register in `core/src/wasm.zig` (for WebAssembly).

3.  **Update Interface**: If the filter requires shared state, use the `ptr` field and cast it within your functions.

## 🕸 WebAssembly Bridge

OMNI uses a custom-packed `u64` return to communicate between Zig and the JavaScript host.
- **High 32 bits**: Length of the result.
- **Low 32 bits**: Memory pointer (relative to Wasm memory).

When modifying the `compress` export in `wasm.zig`, ensure that both memory and string encodings are correctly handled on the TypeScript side (`src/index.ts`).

## 🧪 Testing

Run internal Zig tests:
```bash
cd core
zig test src/main.zig
```

Verification of the Wasm integration can be done using the `test-wasm.js` script (if available) or by starting the MCP server with `npm start`.

## 📦 Release

To build production-ready Wasm:
```bash
cd core
zig build-exe src/wasm.zig -target wasm32-wasi -O ReleaseSmall -rdynamic --name omni-wasm
```

This will produce a small, optimized `.wasm` binary suitable for edge distribution.
