const std = @import("std");
const Filter = @import("interface.zig").Filter;

pub const GitFilter = struct {
    pub fn filter() Filter {
        return .{
            .name = "git",
            .ptr = undefined,
            .matchFn = match,
            .processFn = process,
        };
    }

    fn match(_: *anyopaque, input: []const u8) bool {
        return std.mem.indexOf(u8, input, "On branch") != null;
    }

    fn process(_: *anyopaque, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        const search = "On branch ";
        if (std.mem.indexOf(u8, input, search)) |index| {
            const start = index + search.len;
            const end = if (std.mem.indexOf(u8, input[start..], "\n")) |e| start + e else input.len;
            const branch = input[start..end];
            return try std.fmt.allocPrint(allocator, "git: on branch {s}", .{branch});
        }
        return try allocator.dupe(u8, input);
    }
};
