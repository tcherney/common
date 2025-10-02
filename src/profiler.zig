const string_key_map = @import("string_key_map.zig");
const std = @import("std");
const StringKeyMap = string_key_map.StringKeyMap(u64);
const ProfileString = std.ArrayList([]const u8);

const ENABLED = false;

const Profiler = struct {
    total_elapsed: StringKeyMap,
    head: ProfileLevel,
    current_level: *ProfileLevel,
    current_level_name: ProfileString,
    const ProfileLevel = struct {
        name: ProfileString,
        timer: std.time.Timer,
        parent: ?*ProfileLevel = null,
        is_running: bool = false,
        children: std.ArrayList(ProfileLevel),
    };

    fn init() Profiler {
        return .{};
    }

    fn deinit(self: *Profiler) void {
        self.total_elapsed.deinit();
    }

    fn profile_start(self: *Profiler, name: []const u8) void {
        if (ENABLED) {
            var found: bool = false;
            for (self.current_level.children.items) |*child| {
                if (std.mem.eql(child.name.items, name)) {
                    self.current_level = child;
                    found = true;
                    break;
                }
            }
            if (!found) {
                //TODO add params
                self.current_level.children.append(ProfileLevel());
            }
            //TODO update current_level_string
            self.current_level.timer.start();
        }
    }

    fn profile_end(self: *Profiler) void {
        if (ENABLED) {
            if (self.current_level.is_running) {
                const elapsed = self.current_level.timer.read();
                const entry = try self.total_elapsed.getOrPut(self.current_level_name);
                entry.value_ptr.* += elapsed;
                //TODO update current_level_string
            }
        }
    }
};

test "simple_profile" {}
