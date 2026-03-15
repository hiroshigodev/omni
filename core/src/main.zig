const std = @import("std");
const compressor = @import("compressor.zig");
const Filter = @import("filters/interface.zig").Filter;
const GitFilter = @import("filters/git.zig").GitFilter;
const BuildFilter = @import("filters/build.zig").BuildFilter;
const DockerFilter = @import("filters/docker.zig").DockerFilter;
const SqlFilter = @import("filters/sql.zig").SqlFilter;
const CustomFilter = @import("filters/custom.zig").CustomFilter;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize Filter Registry
    var filters = std.ArrayList(Filter).empty;
    defer filters.deinit(allocator);

    try filters.append(allocator, GitFilter.filter());
    try filters.append(allocator, BuildFilter.filter());
    try filters.append(allocator, DockerFilter.filter());
    try filters.append(allocator, SqlFilter.filter());

    // Load Custom Rules
    var custom_filter_to_deinit: ?*CustomFilter = null;
    defer if (custom_filter_to_deinit) |c| c.deinit();

    const custom_init = CustomFilter.init(allocator, "omni_config.json");
    if (custom_init) |custom| {
        custom_filter_to_deinit = custom;
        try filters.append(allocator, custom.filter());
    } else |_| {}

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len > 1) {
        const cmd = args[1];
        if (std.mem.eql(u8, cmd, "-h") or std.mem.eql(u8, cmd, "--help") or std.mem.eql(u8, cmd, "help")) {
            const help_text =
                \\OMNI Native Core - Semantic Distillation Engine 🌌
                \\
                \\Usage:
                \\  omni < input_file             # Distill input from stdin
                \\  command | omni               # Distill command output via pipe
                \\  omni -v | --version          # Show version
                \\  omni -h | --help             # Show this help
                \\
                \\OMNI is designed to be used as a filter in your agentic pipelines.
                \\
            ;
            try std.fs.File.stdout().deprecatedWriter().print("{s}", .{help_text});
            return;
        } else if (std.mem.eql(u8, cmd, "-v") or std.mem.eql(u8, cmd, "--version") or std.mem.eql(u8, cmd, "version")) {
            try std.fs.File.stdout().deprecatedWriter().print("OMNI Core v0.1.0 (Zig)\n", .{});
            return;
        }
    }

    // Check if we have data on stdin
    var stdin_file = std.fs.File.stdin();
    const input = stdin_file.readToEndAlloc(allocator, 1024 * 1024 * 10) catch |err| {
        if (err == error.EndOfStream) {
            try std.fs.File.stderr().deprecatedWriter().print("Error: No input provided via stdin.\nUse 'omni --help' for usage.\n", .{});
            std.process.exit(1);
        }
        return err;
    };
    defer allocator.free(input);

    if (input.len == 0) {
        try std.fs.File.stderr().deprecatedWriter().print("Error: Empty input provided via stdin.\n", .{});
        std.process.exit(1);
    }

    const compressed = try compressor.compress(allocator, input, filters.items);
    defer allocator.free(compressed);
    
    try std.fs.File.stdout().deprecatedWriter().print("{s}\n", .{compressed});
}

test "compressor integration" {
    const gpa = std.testing.allocator;
    const input = "On branch main\nChanges not staged for commit:";
    const filters = [_]Filter{GitFilter.filter()};
    const result = try compressor.compress(gpa, input, &filters);
    defer gpa.free(result);
    try std.testing.expect(std.mem.indexOf(u8, result, "git: on branch main") != null);
}
