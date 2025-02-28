const std = @import("std");

test "hello world" {
    std.debug.print("hello world", .{});
}

//TODO port over util functions here, more complex structs in seperate files that then get exposed here
pub const StringKeyMap = @import("string_key_map.zig");
pub const Graph = @import("graph.zig");
