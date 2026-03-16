import fs from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import { WASI } from 'wasi';
import { argv, env } from 'process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const wasmPath = join(__dirname, 'core/zig-out/bin/omni-wasm.wasm');
const wasmBuffer = fs.readFileSync(wasmPath);

async function runTest() {
    const wasi = new WASI({
        args: argv,
        env,
        version: 'preview1',
        preopens: {
            '.': '.'
        }
    });

    const importObject = {
        wasi_snapshot_preview1: wasi.wasiImport
    };

    const { instance } = await WebAssembly.instantiate(wasmBuffer, importObject);
    wasi.start(instance);

    const { alloc, free, compress, init_engine, memory } = instance.exports;

    function writeString(str) {
        const bytes = Buffer.from(str);
        const ptr = alloc(bytes.length);
        const mem = new Uint8Array(memory.buffer);
        mem.set(bytes, ptr);
        return { ptr, len: bytes.length };
    }

    function readString(u64) {
        const len = Number(u64 >> 32n);
        const ptr = Number(u64 & 0xFFFFFFFFn);
        const bytes = new Uint8Array(memory.buffer, ptr, len);
        return Buffer.from(bytes).toString();
    }

    const configPath = join(__dirname, 'omni_config.json');
    const backupPath = join(__dirname, 'omni_config.json.bak');
    const baseConfigOrigin = join(__dirname, 'core/omni_config.json');
    const testConfigPath = join(__dirname, 'core/config-test.json');

    try {
        console.log("Setting up test environment...");
        
        if (!fs.existsSync(configPath) && fs.existsSync(baseConfigOrigin)) {
            fs.copyFileSync(baseConfigOrigin, configPath);
        }

        if (fs.existsSync(configPath)) {
            fs.renameSync(configPath, backupPath);
        }
        fs.copyFileSync(testConfigPath, configPath);

        console.log("Initializing OMNI engine...");
        init_engine();

        const testCases = [
            { label: 'HIGH SIGNAL (>0.8)', input: 'SIG_HIGH: data', expected: 'HIGH!' },
            { label: 'GREY AREA (0.3-0.8)', input: 'SIG_GREY: data', expected: '[OMNI Context Manifest: grey-area (Confidence: 0.50)]\nGREY!' },
            { label: 'NOISE (<0.3)', input: 'SIG_NOISE: data', expected: '[OMNI: Dropped noisy noise-signal output (Confidence: 0.20)]' }
        ];

        for (const tc of testCases) {
            console.log(`\nTesting ${tc.label}...`);
            const { ptr, len } = writeString(tc.input);
            const resultPtr = compress(ptr, len);
            const output = readString(resultPtr);
            
            console.log(`Input:  ${tc.input}`);
            console.log(`Output: ${output}`);

            if (output.includes(tc.expected)) {
                console.log(`✅ PASS: ${tc.label}`);
            } else {
                console.log(`❌ FAIL: ${tc.label}`);
                console.log(`   Expected: ${tc.expected}`);
            }
        }

    } finally {
        console.log("\nCleaning up...");
        if (fs.existsSync(backupPath)) {
            if (fs.existsSync(configPath)) fs.unlinkSync(configPath);
            fs.renameSync(backupPath, configPath);
        }
    }
}

runTest().catch(console.error);
