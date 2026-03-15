const std = @import("std");
const Filter = @import("filters/interface.zig").Filter;

pub fn compress(allocator: std.mem.Allocator, input: []const u8, filters: []const Filter) ![]u8 {
    for (filters) |filter| {
        if (filter.match(input)) {
            return filter.process(allocator, input);
        }
    }
    
    // Default: return full input for now
    return try allocator.dupe(u8, input);
}
