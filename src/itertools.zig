const std = @import("std");

pub fn sum(T: type, sequence: []T) T {
    var ret: T = 0;
    for (sequence) |i| {
        ret += i;
    }
    return ret;
}

pub fn combinations(T: type, allocator: std.mem.Allocator, sequence: []T, length: usize) !std.ArrayList(std.ArrayList(T)) {
    var combos = std.ArrayList(std.ArrayList(T)).init(allocator);
    for (0..sequence.len) |i| {
        const rem_items = sequence[i + 1 ..];
        const item = sequence[i];
        if (length > 1) {
            const rem_combos = try combinations(T, allocator, rem_items, length - 1);
            defer rem_combos.deinit();
            for (0..rem_combos.items.len) |j| {
                try rem_combos.items[j].append(item);
                try combos.append(rem_combos.items[j]);
            }
        } else {
            var new_combo = std.ArrayList(T).init(allocator);
            try new_combo.append(item);
            try combos.append(new_combo);
        }
    }
    return combos;
}

pub fn product(T: type, allocator: std.mem.Allocator, lists: *std.ArrayList(std.ArrayList(T))) !std.ArrayList(std.ArrayList(T)) {
    var combos = std.ArrayList(std.ArrayList(T)).init(allocator);
    if (lists.items.len == 0) {
        try combos.append(std.ArrayList(T).init(allocator));
        return combos;
    } else {
        const first_list = lists.pop().?;
        const remaining = try product(T, allocator, lists);
        defer remaining.deinit();
        for (first_list.items) |i| {
            for (remaining.items) |r| {
                var result_list = std.ArrayList(T).init(allocator);
                try result_list.append(i);
                try result_list.appendSlice(r.items);
                try combos.append(result_list);
            }
        }
        first_list.deinit();
    }
    return combos;
}
