const string_key_map = @import("string_key_map.zig");
const std = @import("std");

const Allocator = std.mem.Allocator;
const PROFILER_LOG = std.log.scoped(.profiler);

var ENABLED = true;

const Profiler = if (ENABLED) struct {
    head: ?*ProfileLevel = null,
    current_level: *ProfileLevel = undefined,
    allocator: Allocator,
    const Error = error{NotStarted} || Allocator.Error || std.time.Timer.Error;
    const ProfileString = if (ENABLED) std.ArrayList(u8) else void;
    const LoggingLevel = enum {
        DEBUG,
        ERROR,
        INFO,
        WARN,
    };
    const Units = enum {
        SECONDS,
        MILLISECONDS,
        NANOSECONDS,
    };
    const ProfileLevel = struct {
        name: ProfileString,
        timer: std.time.Timer = undefined,
        parent: ?*ProfileLevel = null,
        total_elapsed: u64 = 0,
        num_events: u64 = 0,
        min: u64 = std.math.maxInt(u64),
        max: u64 = 0,
        is_running: bool = false,
        children: std.ArrayList(*ProfileLevel),
        pub fn init(name: []const u8, parent: ?*ProfileLevel, allocator: Allocator) Error!ProfileLevel {
            var ret = ProfileLevel{
                .name = ProfileString.init(allocator),
                .parent = parent,
                .children = std.ArrayList(*ProfileLevel).init(allocator),
            };
            _ = try ret.name.writer().write(name);
            return ret;
        }
        pub fn deinit(self: *ProfileLevel, allocator: Allocator) void {
            if (ENABLED) {
                for (self.children.items) |child| {
                    child.deinit(allocator);
                    allocator.destroy(child);
                }
                self.children.deinit();
                self.name.deinit();
            }
        }
    };

    pub fn init(allocator: Allocator) Profiler {
        if (ENABLED) {
            return .{ .allocator = allocator };
        }
    }

    pub fn deinit(self: *Profiler) void {
        if (ENABLED) {
            if (self.head) |head| {
                for (head.children.items) |child| {
                    child.deinit(self.allocator);
                    self.allocator.destroy(child);
                }
                self.head.?.children.deinit();
                self.head.?.name.deinit();
                self.allocator.destroy(self.head.?);
            }
        }
    }

    pub fn start(self: *Profiler, name: []const u8) Error!void {
        if (ENABLED) {
            var found: bool = false;
            if (self.head != null) {
                for (self.current_level.children.items) |child| {
                    if (std.mem.eql(u8, child.name.items, name)) {
                        self.current_level = child;
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    const child = try self.allocator.create(ProfileLevel);
                    child.* = try ProfileLevel.init(name, self.current_level, self.allocator);
                    try self.current_level.children.append(child);
                    self.current_level = child;
                }
            } else {
                self.head = try self.allocator.create(ProfileLevel);
                self.head.?.* = try ProfileLevel.init(name, null, self.allocator);
                self.current_level = self.head.?;
            }
            self.current_level.timer = try std.time.Timer.start();
            self.current_level.is_running = true;
        }
    }

    pub fn end(self: *Profiler) void {
        if (ENABLED) {
            if (self.head != null) {
                if (self.current_level.is_running) {
                    const elapsed = self.current_level.timer.read();
                    self.current_level.min = @min(self.current_level.min, elapsed);
                    self.current_level.max = @max(self.current_level.max, elapsed);
                    self.current_level.total_elapsed += elapsed;
                    self.current_level.num_events += 1;
                    self.current_level.is_running = false;
                }
                if (self.current_level.parent) |parent| {
                    self.current_level = parent;
                }
            }
        }
    }

    fn to_seconds(nano: u64) f64 {
        return @as(f64, @floatFromInt(nano)) / @as(f64, @floatFromInt(std.time.ns_per_s));
    }

    fn to_milli(nano: u64) f64 {
        return @as(f64, @floatFromInt(nano)) / @as(f64, @floatFromInt(std.time.ns_per_ms));
    }

    fn to_string_helper(units: Units, current_level: *ProfileLevel, current_nesting: u64, ret: *std.ArrayList(u8)) Error!void {
        for (0..current_nesting) |_| {
            _ = try ret.writer().write("   ");
        }
        //TODO may need to adjust specifiers
        switch (units) {
            .SECONDS => {
                try ret.writer().print("{s} --- min: {d:.4} | max: {d:.4} | mean: {d:.4} | elapsed: {d:.4}\n", .{ current_level.name.items, to_seconds(current_level.min), to_seconds(current_level.max), to_seconds(current_level.total_elapsed) / @as(f64, @floatFromInt(current_level.num_events)), to_seconds(current_level.total_elapsed) });
            },
            .MILLISECONDS => {
                try ret.writer().print("{s} --- min: {d:.4} | max: {d:.4} | mean: {d:.4} | elapsed: {d:.4}\n", .{ current_level.name.items, to_milli(current_level.min), to_milli(current_level.max), to_milli(current_level.total_elapsed) / @as(f64, @floatFromInt(current_level.num_events)), to_milli(current_level.total_elapsed) });
            },
            .NANOSECONDS => {
                try ret.writer().print("{s} --- min: {d:.4} | max: {d:.4} | mean: {d:.4} | elapsed: {d:.4}\n", .{ current_level.name.items, current_level.min, current_level.max, current_level.total_elapsed / current_level.num_events, current_level.total_elapsed });
            },
        }
        for (current_level.children.items) |child| {
            try to_string_helper(units, child, current_nesting + 1, ret);
        }
    }

    pub fn to_string(self: *Profiler, units: Units) Error!ProfileString {
        if (ENABLED) {
            if (self.head) |head| {
                var ret = std.ArrayList(u8).init(self.allocator);
                try to_string_helper(units, head, 0, &ret);
                return ret;
            } else {
                return Error.NotStarted;
            }
        }
    }

    pub fn log(self: *Profiler, level: LoggingLevel, units: Units) Error!void {
        if (ENABLED) {
            const res_str = try self.to_string(units);
            defer res_str.deinit();
            switch (level) {
                .INFO => {
                    PROFILER_LOG.info("{s}", .{res_str.items});
                },
                .WARN => {
                    PROFILER_LOG.warn("{s}", .{res_str.items});
                },
                .DEBUG => {
                    PROFILER_LOG.debug("{s}", .{res_str.items});
                },
                .ERROR => {
                    PROFILER_LOG.err("{s}", .{res_str.items});
                },
            }
        }
    }
} else void;

fn test1(profiler: *Profiler) !void {
    const src_loc = @src();
    try profiler.start(src_loc.fn_name);
    try test2(profiler);
    try test3(profiler);
    try test3(profiler);
    try test3(profiler);
    try test2(profiler);
    try test3(profiler);
    profiler.end();
}

fn test2(profiler: *Profiler) !void {
    const src_loc = @src();
    try profiler.start(src_loc.fn_name);
    try test3(profiler);
    std.time.sleep(std.time.ns_per_ms * std.crypto.random.intRangeAtMost(u64, 1, 30));
    profiler.end();
}

fn test3(profiler: *Profiler) !void {
    const src_loc = @src();
    try profiler.start(src_loc.fn_name);
    std.time.sleep(std.time.ns_per_ms * std.crypto.random.intRangeAtMost(u64, 1, 30));
    profiler.end();
}

test "simple_profile" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var profiler = Profiler.init(allocator);
    try test1(&profiler);
    const res_string = try profiler.to_string();
    std.debug.print("{s}", .{res_string.items});
    res_string.deinit();
    profiler.deinit();
    if (gpa.deinit() == .leak) {
        std.log.warn("Leaked!\n", .{});
    }
}
