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

    var stdin_file = std.fs.File.stdin();
    const input = try stdin_file.readToEndAlloc(allocator, 1024 * 1024 * 10);
    defer allocator.free(input);

    const compressed = try compressor.compress(allocator, input, filters.items);
    defer allocator.free(compressed);
    
    var stdout_buf: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    try stdout_writer.interface.print("{s}\n", .{compressed});
    try stdout_writer.interface.flush();
}

test "compressor integration" {
    const gpa = std.testing.allocator;
    const input = "On branch main\nChanges not staged for commit:";
    const filters = [_]Filter{GitFilter.filter()};
    const result = try compressor.compress(gpa, input, &filters);
    defer gpa.free(result);
    try std.testing.expect(std.mem.indexOf(u8, result, "git: on branch main") != null);
}
