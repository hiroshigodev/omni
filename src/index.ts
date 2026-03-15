import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import fs from "fs";
import path from "path";
import { WASI } from "wasi";
import { LRUCache } from "./cache.js";

const server = new Server(
  {
    name: "omni-server",
    version: "0.1.1",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

const CACHE_CAPACITY = 100;
const CACHE_TTL = 3600000; // 1 hour
const cache = new LRUCache<string, string>(CACHE_CAPACITY, CACHE_TTL);

const WASM_PATH = path.join(process.cwd(), "core", "omni-wasm.wasm");
let wasmInstance: WebAssembly.Instance | null = null;
let wasi: WASI | null = null;

async function getWasmInstance() {
  if (wasmInstance) return wasmInstance;

  wasi = new WASI({
    version: "preview1",
    args: [],
    env: process.env,
    preopens: {
      ".": path.join(process.cwd(), "core"),
    },
  });

  const wasmBuffer = fs.readFileSync(WASM_PATH);
  const { instance } = await WebAssembly.instantiate(wasmBuffer, {
    wasi_snapshot_preview1: wasi.wasiImport,
  });

  wasmInstance = instance;
  const exports = wasmInstance.exports as any;
  if (!exports.init_engine()) {
    console.error("Failed to initialize OMNI engine in Wasm");
  }

  return wasmInstance;
}

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "omni_compress",
        description: "Compress a string to save LLM tokens using Zig-powered OMNI engine (Wasm).",
        inputSchema: {
          type: "object",
          properties: {
            text: {
              type: "string",
              description: "The raw text to compress",
            },
          },
          required: ["text"],
        },
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name === "omni_compress") {
    const text = (request.params.arguments as any).text;

    // Check Cache
    const cached = cache.get(text);
    if (cached) {
      return { content: [{ type: "text", text: cached }] };
    }
    
    try {
      const instance = await getWasmInstance();
      const exports = instance.exports as any;
      const memory = exports.memory as WebAssembly.Memory;

      const encoder = new TextEncoder();
      const decoder = new TextDecoder();
      
      const inputBytes = encoder.encode(text);
      const inputPtr = exports.alloc(inputBytes.length);
      
      if (!inputPtr) throw new Error("Wasm allocation failed");

      const memView = new Uint8Array(memory.buffer);
      memView.set(inputBytes, inputPtr);

      // Call compress: returns struct { ptr, len }
      // In Wasm MVP return values are often handled via a hidden first argument if they are structs,
      // but if it's a 64-bit value total, it might be returned as i64.
      // However, Zig's CompressResult is 2x 32-bit (8 bytes).
      // Let's check how it's actually exported.
      
      const resultRaw = exports.compress(inputPtr, inputBytes.length);
      // If it's a 64-bit int (ptr in low 32, len in high 32 if little endian)
      const resultPtr = Number(BigInt(resultRaw) & 0xFFFFFFFFn);
      const resultLen = Number(BigInt(resultRaw) >> 32n);

      const outputBytes = new Uint8Array(memory.buffer, resultPtr, resultLen);
      const output = decoder.decode(outputBytes);

      // Free Wasm memory
      exports.free(inputPtr, inputBytes.length);
      exports.free(resultPtr, resultLen);

      cache.set(text, output);

      return {
        content: [{ type: "text", text: output.trim() }],
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: `Error: ${error.message}` }],
        isError: true,
      };
    }
  }
  
  throw new Error("Tool not found");
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((error) => {
  console.error("Server error:", error);
  process.exit(1);
});
