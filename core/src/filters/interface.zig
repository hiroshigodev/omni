const std = @import("std");

pub const Filter = struct {
    name: []const u8,
    ptr: *anyopaque,
    matchFn: *const fn (ptr: *anyopaque, input: []const u8) bool,
    processFn: *const fn (ptr: *anyopaque, allocator: std.mem.Allocator, input: []const u8) anyerror![]u8,

    pub fn match(self: Filter, input: []const u8) bool {
        return self.matchFn(self.ptr, input);
    }

    pub fn process(self: Filter, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        return self.processFn(self.ptr, allocator, input);
    }
};
