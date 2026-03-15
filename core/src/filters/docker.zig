const std = @import("std");
const Filter = @import("interface.zig").Filter;

pub const DockerFilter = struct {
    pub fn filter() Filter {
        return .{
            .name = "docker",
            .ptr = undefined,
            .matchFn = match,
            .processFn = process,
        };
    }

    fn match(_: *anyopaque, input: []const u8) bool {
        return std.mem.indexOf(u8, input, "Step ") != null or std.mem.indexOf(u8, input, "CACHED") != null;
    }

    fn process(_: *anyopaque, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        var it = std.mem.splitScalar(u8, input, '\n');
        var result = std.ArrayList(u8).empty;
        errdefer result.deinit(allocator);

        while (it.next()) |line| {
            // Keep Step definitions, CACHED indicators, and actual errors
            if (std.mem.indexOf(u8, line, "Step ") != null or 
                std.mem.indexOf(u8, line, "CACHED") != null or
                std.mem.indexOf(u8, line, "ERROR") != null or
                std.mem.indexOf(u8, line, "failed") != null) 
            {
                try result.appendSlice(allocator, line);
                try result.append(allocator, '\n');
            }
        }

        if (result.items.len == 0) {
            return try allocator.dupe(u8, "[Docker log noise omitted]");
        }

        return try result.toOwnedSlice(allocator);
    }
};
