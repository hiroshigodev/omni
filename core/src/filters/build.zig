const std = @import("std");
const Filter = @import("interface.zig").Filter;

pub const BuildFilter = struct {
    pub fn filter() Filter {
        return .{
            .name = "build",
            .ptr = undefined,
            .matchFn = match,
            .processFn = process,
        };
    }

    fn match(_: *anyopaque, input: []const u8) bool {
        return std.mem.indexOf(u8, input, "error:") != null or std.mem.indexOf(u8, input, "warning:") != null;
    }

    fn process(_: *anyopaque, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        // Simple summarizer: Keep only lines with errors or warnings
        var it = std.mem.splitScalar(u8, input, '\n');
        var result = std.ArrayList(u8).empty;
        errdefer result.deinit(allocator);

        while (it.next()) |line| {
            if (std.mem.indexOf(u8, line, "error:") != null or std.mem.indexOf(u8, line, "warning:") != null) {
                try result.appendSlice(allocator, line);
                try result.append(allocator, '\n');
            }
        }

        if (result.items.len == 0) {
            return try allocator.dupe(u8, "[build log with noise omitted]");
        }

        return try result.toOwnedSlice(allocator);
    }
};
