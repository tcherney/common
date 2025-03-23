// Hashmap wrapper that allocates keys
const std = @import("std");

pub fn StringKeyMap(comptime V: type) type {
    const K = []const u8;
    const KV = std.StringHashMap(V).KV;
    const Size = std.StringHashMap(V).Size;
    const GetOrPutResult = std.StringHashMap(V).GetOrPutResult;
    const Iterator = std.StringHashMap(V).Iterator;
    const KeyIterator = std.StringHashMap(V).KeyIterator;
    const ValueIterator = std.StringHashMap(V).ValueIterator;
    const Entry = std.StringHashMap(V).Entry;
    return struct {
        internal_map: std.StringHashMap(V),
        allocator: std.mem.Allocator,
        keys: std.ArrayList(std.ArrayList(u8)),
        pub const Self = @This();
        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .internal_map = std.StringHashMap(V).init(allocator),
                .allocator = allocator,
                .keys = std.ArrayList(std.ArrayList(u8)).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.internal_map.deinit();
            for (0..self.keys.items.len) |i| {
                self.keys.items[i].deinit();
            }
            self.keys.deinit();
        }

        //TODO could support more features
        fn add_key(self: *Self, key: []const u8) !void {
            for (0..self.keys.items.len) |i| {
                if (std.mem.eql(u8, self.keys.items[i].items, key)) return;
            }
            try self.keys.append((std.ArrayList(u8).init(self.allocator)));
            _ = try self.keys.items[self.keys.items.len - 1].writer().write(key);
        }

        /// Empty the map, but keep the backing allocation for future use.
        /// This does *not* free keys or values! Be sure to
        /// release them if they need deinitialization before
        /// calling this function.
        pub fn clearRetainingCapacity(self: *Self) void {
            return self.internal_map.clearRetainingCapacity();
        }

        /// Empty the map and release the backing allocation.
        /// This does *not* free keys or values! Be sure to
        /// release them if they need deinitialization before
        /// calling this function.
        pub fn clearAndFree(self: *Self) void {
            return self.internal_map.clearAndFree();
        }

        /// Return the number of items in the map.
        pub fn count(self: Self) Size {
            return self.internal_map.count();
        }

        /// Create an iterator over the entries in the map.
        /// The iterator is invalidated if the map is modified.
        pub fn iterator(self: *const Self) Iterator {
            return self.internal_map.iterator();
        }

        /// Create an iterator over the keys in the map.
        /// The iterator is invalidated if the map is modified.
        pub fn keyIterator(self: Self) KeyIterator {
            return self.internal_map.keyIterator();
        }

        /// Create an iterator over the values in the map.
        /// The iterator is invalidated if the map is modified.
        pub fn valueIterator(self: Self) ValueIterator {
            return self.internal_map.valueIterator();
        }

        /// If key exists this function cannot fail.
        /// If there is an existing item with `key`, then the result's
        /// `Entry` pointers point to it, and found_existing is true.
        /// Otherwise, puts a new item with undefined value, and
        /// the `Entry` pointers point to it. Caller should then initialize
        /// the value (but not the key).
        pub fn getOrPut(self: *Self, key: K) std.mem.Allocator.Error!GetOrPutResult {
            try self.add_key(key);
            return self.internal_map.getOrPut(key);
        }

        /// If key exists this function cannot fail.
        /// If there is an existing item with `key`, then the result's
        /// `Entry` pointers point to it, and found_existing is true.
        /// Otherwise, puts a new item with undefined key and value, and
        /// the `Entry` pointers point to it. Caller must then initialize
        /// the key and value.
        pub fn getOrPutAdapted(self: *Self, key: anytype, ctx: anytype) std.mem.Allocator.Error!GetOrPutResult {
            try self.add_key(key);
            return self.internal_map.getOrPutAdapted(key, ctx);
        }

        /// If there is an existing item with `key`, then the result's
        /// `Entry` pointers point to it, and found_existing is true.
        /// Otherwise, puts a new item with undefined value, and
        /// the `Entry` pointers point to it. Caller should then initialize
        /// the value (but not the key).
        /// If a new entry needs to be stored, this function asserts there
        /// is enough capacity to store it.
        pub fn getOrPutAssumeCapacity(self: *Self, key: K) GetOrPutResult {
            try self.add_key(key);
            return self.internal_map.getOrPutAssumeCapacity(key);
        }

        /// If there is an existing item with `key`, then the result's
        /// `Entry` pointers point to it, and found_existing is true.
        /// Otherwise, puts a new item with undefined value, and
        /// the `Entry` pointers point to it. Caller must then initialize
        /// the key and value.
        /// If a new entry needs to be stored, this function asserts there
        /// is enough capacity to store it.
        pub fn getOrPutAssumeCapacityAdapted(self: *Self, key: anytype, ctx: anytype) GetOrPutResult {
            try self.add_key(key);
            return self.internal_map.getOrPutAssumeCapacityAdapted(key, ctx);
        }

        pub fn getOrPutValue(self: *Self, key: K, value: V) std.mem.Allocator.Error!Entry {
            try self.add_key(key);
            return self.internal_map.getOrPutValue(key, value);
        }

        /// Increases capacity, guaranteeing that insertions up until the
        /// `expected_count` will not cause an allocation, and therefore cannot fail.
        pub fn ensureTotalCapacity(self: *Self, expected_count: Size) std.mem.Allocator.Error!void {
            return self.internal_map.ensureTotalCapacity(expected_count);
        }

        /// Increases capacity, guaranteeing that insertions up until
        /// `additional_count` **more** items will not cause an allocation, and
        /// therefore cannot fail.
        pub fn ensureUnusedCapacity(self: *Self, additional_count: Size) std.mem.Allocator.Error!void {
            return self.internal_map.ensureUnusedCapacity(additional_count);
        }

        /// Returns the number of total elements which may be present before it is
        /// no longer guaranteed that no allocations will be performed.
        pub fn capacity(self: Self) Size {
            return self.internal_map.capacity();
        }

        /// Clobbers any existing data. To detect if a put would clobber
        /// existing data, see `getOrPut`.
        pub fn put(self: *Self, key: K, value: V) std.mem.Allocator.Error!void {
            try self.add_key(key);
            return self.internal_map.put(key, value);
        }

        /// Inserts a key-value pair into the hash map, asserting that no previous
        /// entry with the same key is already present
        pub fn putNoClobber(self: *Self, key: K, value: V) std.mem.Allocator.Error!void {
            try self.add_key(key);
            return self.internal_map.putNoClobber(key, value);
        }

        /// Asserts there is enough capacity to store the new key-value pair.
        /// Clobbers any existing data. To detect if a put would clobber
        /// existing data, see `getOrPutAssumeCapacity`.
        pub fn putAssumeCapacity(self: *Self, key: K, value: V) void {
            try self.add_key(key);
            return self.internal_map.putAssumeCapacity(key, value);
        }

        /// Asserts there is enough capacity to store the new key-value pair.
        /// Asserts that it does not clobber any existing data.
        /// To detect if a put would clobber existing data, see `getOrPutAssumeCapacity`.
        pub fn putAssumeCapacityNoClobber(self: *Self, key: K, value: V) void {
            try self.add_key(key);
            return self.internal_map.putAssumeCapacityNoClobber(key, value);
        }

        /// Inserts a new `Entry` into the hash map, returning the previous one, if any.
        pub fn fetchPut(self: *Self, key: K, value: V) std.mem.Allocator.Error!?KV {
            try self.add_key(key);
            return self.internal_map.fetchPut(key, value);
        }

        /// Inserts a new `Entry` into the hash map, returning the previous one, if any.
        /// If insertion happens, asserts there is enough capacity without allocating.
        pub fn fetchPutAssumeCapacity(self: *Self, key: K, value: V) ?KV {
            try self.add_key(key);
            return self.internal_map.fetchPutAssumeCapacity(key, value);
        }

        /// Removes a value from the map and returns the removed kv pair.
        pub fn fetchRemove(self: *Self, key: K) ?std.StringHashMap(V).KV {
            return self.internal_map.fetchRemove(key);
        }

        pub fn fetchRemoveAdapted(self: *Self, key: anytype, ctx: anytype) ?KV {
            return self.internal_map.fetchRemoveAdapted(key, ctx);
        }

        /// Finds the value associated with a key in the map
        pub fn get(self: Self, key: K) ?V {
            return self.internal_map.get(key);
        }
        pub fn getAdapted(self: Self, key: anytype, ctx: anytype) ?V {
            return self.internal_map.getAdapted(key, ctx);
        }

        pub fn getPtr(self: Self, key: K) ?*V {
            return self.internal_map.getPtr(key);
        }
        pub fn getPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*V {
            return self.internal_map.getPtrAdapted(key, ctx);
        }

        /// Finds the actual key associated with an adapted key in the map
        pub fn getKey(self: Self, key: K) ?K {
            return self.internal_map.getKey(key);
        }
        pub fn getKeyAdapted(self: Self, key: anytype, ctx: anytype) ?K {
            return self.internal_map.getKeyAdapted(key, ctx);
        }

        pub fn getKeyPtr(self: Self, key: K) ?*K {
            return self.internal_map.getKeyPtr(key);
        }
        pub fn getKeyPtrAdapted(self: Self, key: anytype, ctx: anytype) ?*K {
            return self.internal_map.getKeyPtrAdapted(key, ctx);
        }

        /// Finds the key and value associated with a key in the map
        pub fn getEntry(self: Self, key: K) ?Entry {
            return self.internal_map.getEntry(key);
        }

        pub fn getEntryAdapted(self: Self, key: anytype, ctx: anytype) ?Entry {
            return self.internal_map.getEntryAdapted(key, ctx);
        }

        /// Check if the map contains a key
        pub fn contains(self: Self, key: K) bool {
            return self.internal_map.contains(key);
        }

        pub fn containsAdapted(self: Self, key: anytype, ctx: anytype) bool {
            return self.containsAdapted(key, ctx);
        }

        /// If there is an `Entry` with a matching key, it is deleted from
        /// the hash map, and this function returns true.  Otherwise this
        /// function returns false.
        pub fn remove(self: *Self, key: K) bool {
            return self.internal_map.remove(key);
        }

        pub fn removeAdapted(self: *Self, key: anytype, ctx: anytype) bool {
            return self.internal_map.removeAdapted(key, ctx);
        }

        /// Delete the entry with key pointed to by key_ptr from the hash map.
        /// key_ptr is assumed to be a valid pointer to a key that is present
        /// in the hash map.
        pub fn removeByPtr(self: *Self, key_ptr: *K) void {
            self.internal_map.removeByPtr(key_ptr);
        }

        /// Creates a copy of this map, using the same allocator
        pub fn clone(self: Self) std.mem.Allocator.Error!Self {
            return Self{
                .internal_map = self.internal_map.clone(),
                .allocator = self.allocator,
                .keys = self.keys.clone(),
            };
        }

        /// Set the map to an empty state, making deinitialization a no-op, and
        /// returning a copy of the original.
        pub fn move(self: *Self) Self {
            self.internal_map.move();
        }

        /// Rehash the map, in-place.
        ///
        /// Over time, due to the current tombstone-based implementation, a
        /// HashMap could become fragmented due to the buildup of tombstone
        /// entries that causes a performance degradation due to excessive
        /// probing. The kind of pattern that might cause this is a long-lived
        /// HashMap with repeated inserts and deletes.
        ///
        /// After this function is called, there will be no tombstones in
        /// the HashMap, each of the entries is rehashed and any existing
        /// key/value pointers into the HashMap are invalidated.
        pub fn rehash(self: *Self) void {
            self.internal_map.rehash();
        }
    };
}

test "key test" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var map = StringKeyMap(u32).init(allocator);
    try map.put("hello", 1);
    try map.put("world", 2);
    std.log.warn("{d}, {d}", .{ map.get("hello").?, map.get("world").? });
    map.deinit();
    if (gpa.deinit() == .leak) {
        std.log.warn("Leaked!\n", .{});
    }
}
