const std = @import("std");

//TODO port over util functions here, more complex structs in seperate files that then get exposed here
//TODO add docs for all of this
pub const StringKeyMap = @import("string_key_map.zig").StringKeyMap;
pub const Graph = @import("graph.zig");
pub const Mat = @import("matrix.zig").Mat;
pub const Colors = @import("colors.zig").Colors;
pub const itertools = @import("itertools.zig");

const COMMON = @This();
const COMMON_LOG = std.log.scoped(.common);

var timer: std.time.Timer = undefined;
/// Starts a timer and stores it in the `timer` variable. The function returns an error if the timer fails to start, otherwise it returns void. The timer can be used to measure elapsed time by calling the `timer_end` function after some code has executed.
pub fn timer_start() std.time.Timer.Error!void {
    timer = try std.time.Timer.start();
}

/// Ends the timer started by `timer_start` and returns the elapsed time in seconds as a floating-point number. The function reads the elapsed time from the timer, converts it to seconds, logs the elapsed time using the `COMMON_LOG` logger, resets the timer for future use, and returns the elapsed time in seconds.
pub fn timer_end() f64 {
    const ret = @as(f64, @floatFromInt(timer.read())) / 1000000000.0;
    COMMON_LOG.info("{d} s elapsed.\n", .{ret});
    timer.reset();
    return ret;
}

/// Starts a timer and returns it. The caller is responsible for ending the timer and calculating the elapsed time using the `timer_end_param` function.
pub fn timer_start_param() std.time.Timer.Error!std.time.Timer {
    return try std.time.Timer.start();
}

/// Ends the timer passed as a parameter and returns the elapsed time in seconds as a floating-point number. The function reads the elapsed time from the timer, converts it to seconds, logs the elapsed time using the `COMMON_LOG` logger, resets the timer for future use, and returns the elapsed time in seconds.
pub fn timer_end_param(t: *std.time.Timer) f64 {
    const ret = @as(f64, @floatFromInt(t.read())) / 1000000000.0;
    COMMON_LOG.info("{d} s elapsed.\n", .{ret});
    t.reset();
    return ret;
}

/// A struct representing a colored terminal output. It provides a set of color codes for different colors and a method for formatting strings with the specified color.
pub const ColoredTerminal = struct {
    pub const colors = .{
        .red = "\x1B[91m",
        .green = "\x1B[92m",
        .yellow = "\x1B[93m",
        .blue = "\x1B[94m",
        .magenta = "\x1B[95m",
        .cyan = "\x1B[96m",
        .dark_red = "\x1B[31m",
        .dark_green = "\x1B[32m",
        .dark_yellow = "\x1B[33m",
        .dark_blue = "\x1B[34m",
        .dark_magenta = "\x1B[35m",
        .dark_cyan = "\x1B[36m",
        .white = "\x1B[37m",
        .end = "\x1B[0m",
    };

    pub fn colored_format(comptime fmt: []const u8, color: @Type(.enum_literal)) []const u8 {
        const color_str = switch (color) {
            .red => colors.red,
            .green => colors.green,
            .yellow => colors.yellow,
            .blue => colors.blue,
            .magenta => colors.magenta,
            .cyan => colors.cyan,
            .dark_red => colors.dark_red,
            .dark_green => colors.dark_green,
            .dark_yellow => colors.dark_yellow,
            .dark_blue => colors.dark_blue,
            .dark_magenta => colors.dark_magenta,
            .dark_cyan => colors.dark_cyan,
            .white => colors.white,
            else => unreachable,
        };
        return color_str ++ fmt ++ colors.end;
    }
};

/// A struct representing a pixel with RGBA components. The components are stored in a 4-element vector of unsigned 8-bit integers, where the first element represents the red component, the second element represents the green component, the third element represents the blue component, and the fourth element represents the alpha (transparency) component. The struct provides methods for initializing a pixel with specific RGBA values, getting and setting individual color components, checking for equality between two pixels, performing linear interpolation between two pixels, and creating a copy of a pixel.
pub const Pixel = struct {
    v: vec4 = .{ 0, 0, 0, 255 },
    pub const vec4 = @Vector(4, u8);
    pub fn init(r: u8, g: u8, b: u8, a: ?u8) Pixel {
        return Pixel{
            .v = .{
                r, g, b, if (a == null) 255 else a.?,
            },
        };
    }
    pub inline fn get_r(self: *const Pixel) u8 {
        return self.v[0];
    }
    pub inline fn set_r(self: *Pixel, val: u8) void {
        self.v[0] = val;
    }
    pub inline fn get_b(self: *const Pixel) u8 {
        return self.v[2];
    }
    pub inline fn set_b(self: *Pixel, val: u8) void {
        self.v[2] = val;
    }
    pub inline fn get_g(self: *const Pixel) u8 {
        return self.v[1];
    }
    pub inline fn set_g(self: *Pixel, val: u8) void {
        self.v[1] = val;
    }
    pub inline fn get_a(self: *const Pixel) u8 {
        return self.v[3];
    }
    pub inline fn set_a(self: *Pixel, val: u8) void {
        self.v[3] = val;
    }
    pub fn eql(self: *Pixel, other: Pixel) bool {
        return @reduce(.And, self.v == other.v);
    }
    pub fn lerp(self: *Pixel, other: Pixel, t: f64) Pixel {
        const r: u8 = @as(u8, @intFromFloat(COMMON.lerp(@floatFromInt(self.get_r()), @floatFromInt(other.get_r()), t)));
        const g: u8 = @as(u8, @intFromFloat(COMMON.lerp(@floatFromInt(self.get_g()), @floatFromInt(other.get_g()), t)));
        const b: u8 = @as(u8, @intFromFloat(COMMON.lerp(@floatFromInt(self.get_b()), @floatFromInt(other.get_b()), t)));
        const a: u8 = @as(u8, @intFromFloat(COMMON.lerp(@floatFromInt(self.get_a()), @floatFromInt(other.get_a()), t)));
        return .{
            .v = .{
                r, g, b, a,
            },
        };
    }
    pub fn copy(self: *const Pixel) Pixel {
        return .{ .v = .{ self.v[0], self.v[1], self.v[2], self.v[3] } };
    }
};

/// Performs linear interpolation between two values `v0` and `v1` based on a parameter `t` that ranges from 0 to 1. The function returns a value that is `t` percent of the way from `v0` to `v1`. For example, if `t` is 0.5, the function will return the midpoint between `v0` and `v1`.
pub fn lerp(v0: f64, v1: f64, t: f64) f64 {
    return v0 + t * (v1 - v0);
}

/// Returns the maximum value in an array `arr` of type `T`. The function iterates through the elements of the array and keeps track of the maximum value found so far. If the array has only one element, that element is returned as the maximum. If the array is empty, the function is marked as unreachable, indicating that it should never be called with an empty array. The function assumes that the type `T` supports comparison using the greater-than operator (`>`).
pub fn max_array(comptime T: type, arr: []T) T {
    if (arr.len == 1) {
        return arr[0];
    } else if (arr.len == 0) {
        unreachable;
    }
    var max_t: T = arr[0];
    for (1..arr.len) |i| {
        if (arr[i] > max_t) {
            max_t = arr[i];
        }
    }
    return max_t;
}

/// Writes an integer to a file in little endian byte order. The number of bytes to write is determined by the `num_bytes` parameter, which must be either 2 or 4. The integer to write is given by the `i` parameter, which must fit within the specified number of bytes.
pub fn write_little_endian(file: *const std.fs.File, num_bytes: comptime_int, i: u32) std.fs.File.Writer.Error!void {
    switch (num_bytes) {
        2 => {
            try file.writer().writeInt(u16, @as(u16, @intCast(i)), std.builtin.Endian.little);
        },
        4 => {
            try file.writer().writeInt(u32, i, std.builtin.Endian.little);
        },
        else => unreachable,
    }
}

/// A utility struct for representing a Huffman tree. It supports inserting codewords with associated symbols, and deinitializing the tree to free memory.
pub fn HuffmanTree(comptime T: type) type {
    return struct {
        root: Node,
        allocator: std.mem.Allocator,
        const Self = @This();
        pub const Error = error{} || std.mem.Allocator.Error;
        pub const Node = struct {
            symbol: T,
            left: ?*Node,
            right: ?*Node,
            pub fn init() Node {
                return Node{
                    .symbol = ' ',
                    .left = null,
                    .right = null,
                };
            }
        };
        pub fn init(allocator: std.mem.Allocator) Error!HuffmanTree(T) {
            return .{
                .root = Node.init(),
                .allocator = allocator,
            };
        }
        pub fn deinit_node(self: *Self, node: ?*Node) void {
            if (node) |parent| {
                self.deinit_node(parent.left);
                self.deinit_node(parent.right);
                self.allocator.destroy(parent);
            }
        }
        pub fn deinit(self: *Self) void {
            self.deinit_node(self.root.left);
            self.deinit_node(self.root.right);
        }
        pub fn insert(self: *Self, codeword: T, n: T, symbol: T) Error!void {
            //std.debug.print("inserting {b} with length {d} and symbol {d}\n", .{ codeword, n, symbol });
            var node: *Node = &self.root;
            var i = n - 1;
            var next_node: ?*Node = null;
            while (i >= 0) : (i -= 1) {
                const b = codeword & std.math.shl(T, 1, i);
                //std.debug.print("b {d}\n", .{b});
                if (b != 0) {
                    if (node.right) |right| {
                        next_node = right;
                    } else {
                        node.right = try self.allocator.create(Node);
                        node.right.?.* = Node.init();
                        next_node = node.right;
                    }
                } else {
                    if (node.left) |left| {
                        next_node = left;
                    } else {
                        node.left = try self.allocator.create(Node);
                        node.left.?.* = Node.init();
                        next_node = node.left;
                    }
                }
                node = next_node.?;
                if (i == 0) break;
            }
            node.symbol = symbol;
        }
    };
}

/// A utility struct for reading bytes from a byte buffer. It supports options for reading from a file or from an existing buffer, and for taking ownership of the buffer data when reading from a file.
pub const ByteStream = struct {
    index: usize = 0,
    buffer: []u8 = undefined,
    allocator: std.mem.Allocator = undefined,
    own_data: bool = false,
    pub const Error = error{ OutOfBounds, InvalidArgs, FileTooBig } || std.fs.File.OpenError || std.mem.Allocator.Error || std.fs.File.Reader.Error;
    pub fn init(options: anytype) Error!ByteStream {
        const ArgsType = @TypeOf(options);
        const args_type_info = @typeInfo(ArgsType);
        if (args_type_info != .@"struct") {
            return Error.InvalidArgs;
        }
        var buffer: []u8 = undefined;
        var allocator: std.mem.Allocator = undefined;
        var own_data: bool = false;
        if (@hasField(ArgsType, "data")) {
            buffer = @field(options, "data");
        } else if (@hasField(ArgsType, "file_name") and @hasField(ArgsType, "allocator")) {
            allocator = @field(options, "allocator");
            own_data = true;
            const file = try std.fs.cwd().openFile(@field(options, "file_name"), .{});
            defer file.close();
            const size_limit = std.math.maxInt(u32);
            buffer = try file.readToEndAlloc(allocator, size_limit);
        } else {
            return Error.InvalidArgs;
        }
        return ByteStream{
            .buffer = buffer,
            .allocator = allocator,
            .own_data = own_data,
        };
    }
    pub fn deinit(self: *ByteStream) void {
        if (self.own_data) {
            self.allocator.free(self.buffer);
        }
    }
    pub fn getPos(self: *ByteStream) usize {
        return self.index;
    }
    pub fn setPos(self: *ByteStream, index: usize) void {
        self.index = index;
    }
    pub fn getEndPos(self: *ByteStream) usize {
        return self.buffer.len - 1;
    }
    pub fn peek(self: *ByteStream) Error!u8 {
        if (self.index > self.buffer.len - 1) {
            return Error.OutOfBounds;
        }
        return self.buffer[self.index];
    }
    pub fn readByte(self: *ByteStream) Error!u8 {
        if (self.index > self.buffer.len - 1) {
            return Error.OutOfBounds;
        }
        self.index += 1;
        return self.buffer[self.index - 1];
    }
};

/// A utility struct for reading bits from a byte stream. It supports options for JPEG filtering, little endian byte order, and reverse bit order.
pub const BitReader = struct {
    next_byte: u32 = 0,
    next_bit: u32 = 0,
    byte_stream: ByteStream = undefined,
    jpeg_filter: bool = false,
    little_endian: bool = false,
    reverse_bit_order: bool = false,
    const Self = @This();
    pub const Error = error{
        InvalidRead,
        InvalidArgs,
        InvalidEOI,
    } || ByteStream.Error;

    pub fn init(options: anytype) Error!BitReader {
        var bit_reader: BitReader = BitReader{};
        bit_reader.byte_stream = try ByteStream.init(options);
        try bit_reader.set_options(options);
        return bit_reader;
    }

    pub fn set_options(self: *Self, options: anytype) Error!void {
        const ArgsType = @TypeOf(options);
        const args_type_info = @typeInfo(ArgsType);
        if (args_type_info != .@"struct") {
            return Error.InvalidArgs;
        }

        self.little_endian = if (@hasField(ArgsType, "little_endian")) @field(options, "little_endian") else false;
        self.jpeg_filter = if (@hasField(ArgsType, "jpeg_filter")) @field(options, "jpeg_filter") else false;
        self.reverse_bit_order = if (@hasField(ArgsType, "reverse_bit_order")) @field(options, "reverse_bit_order") else false;
    }
    pub fn deinit(self: *Self) void {
        self.byte_stream.deinit();
    }
    pub fn setPos(self: *Self, index: usize) void {
        self.byte_stream.setPos(index);
    }
    pub fn getPos(self: *Self) usize {
        return self.byte_stream.getPos();
    }
    pub fn has_bits(self: *Self) bool {
        return if (self.byte_stream.getPos() != self.byte_stream.getEndPos()) true else false;
    }

    pub fn read(self: *Self, comptime T: type) Error!T {
        self.next_bit = 0;
        var ret: T = undefined;
        switch (T) {
            u8 => {
                ret = try self.byte_stream.readByte();
            },
            i8 => {
                ret = @as(i8, @bitCast(try self.byte_stream.readByte()));
            },
            u16 => {
                ret = @as(u16, @intCast(try self.byte_stream.readByte()));
                if (self.little_endian) {
                    ret |= @as(u16, @intCast(try self.byte_stream.readByte())) << 8;
                } else {
                    ret <<= 8;
                    ret += try self.byte_stream.readByte();
                }
            },
            i16 => {
                ret = @as(i16, @bitCast(@as(u16, @intCast(try self.byte_stream.readByte()))));
                if (self.little_endian) {
                    ret |= @as(i16, @bitCast(@as(u16, @intCast(try self.byte_stream.readByte())))) << 8;
                } else {
                    ret <<= 8;
                    ret += try self.byte_stream.readByte();
                }
            },
            u32 => {
                ret = @as(u32, @intCast(try self.byte_stream.readByte()));
                if (self.little_endian) {
                    ret |= @as(u32, @intCast(try self.byte_stream.readByte())) << 8;
                    ret |= @as(u32, @intCast(try self.byte_stream.readByte())) << 16;
                    ret |= @as(u32, @intCast(try self.byte_stream.readByte())) << 24;
                } else {
                    ret <<= 24;
                    ret |= @as(u32, @intCast(try self.byte_stream.readByte())) << 16;
                    ret |= @as(u32, @intCast(try self.byte_stream.readByte())) << 8;
                    ret |= @as(u32, @intCast(try self.byte_stream.readByte()));
                }
            },
            i32 => {
                ret = @as(i32, @bitCast(@as(u32, @intCast(try self.byte_stream.readByte()))));
                if (self.little_endian) {
                    ret |= @as(i32, @bitCast(@as(u32, @intCast(try self.byte_stream.readByte())))) << 8;
                    ret |= @as(i32, @bitCast(@as(u32, @intCast(try self.byte_stream.readByte())))) << 16;
                    ret |= @as(i32, @bitCast(@as(u32, @intCast(try self.byte_stream.readByte())))) << 24;
                } else {
                    ret <<= 24;
                    ret |= @as(i32, @bitCast(@as(u32, @intCast(try self.byte_stream.readByte())))) << 16;
                    ret |= @as(i32, @bitCast(@as(u32, @intCast(try self.byte_stream.readByte())))) << 8;
                    ret |= @as(i32, @bitCast(@as(u32, @intCast(try self.byte_stream.readByte()))));
                }
            },
            u64 => {
                ret = @as(u64, @intCast(try self.byte_stream.readByte()));
                if (self.little_endian) {
                    ret |= @as(u64, @intCast(try self.byte_stream.readByte())) << 8;
                    ret |= @as(u64, @intCast(try self.byte_stream.readByte())) << 16;
                    ret |= @as(u64, @intCast(try self.byte_stream.readByte())) << 24;
                    ret |= @as(u64, @intCast(try self.byte_stream.readByte())) << 32;
                    ret |= @as(u64, @intCast(try self.byte_stream.readByte())) << 40;
                    ret |= @as(u64, @intCast(try self.byte_stream.readByte())) << 48;
                    ret |= @as(u64, @intCast(try self.byte_stream.readByte())) << 56;
                } else {
                    ret <<= 56;
                    ret |= @as(u64, @intCast(try self.byte_stream.readByte())) << 48;
                    ret |= @as(u64, @intCast(try self.byte_stream.readByte())) << 40;
                    ret |= @as(u64, @intCast(try self.byte_stream.readByte())) << 32;
                    ret |= @as(u64, @intCast(try self.byte_stream.readByte())) << 24;
                    ret |= @as(u64, @intCast(try self.byte_stream.readByte())) << 16;
                    ret |= @as(u64, @intCast(try self.byte_stream.readByte())) << 8;
                    ret |= @as(u64, @intCast(try self.byte_stream.readByte()));
                }
            },
            usize => {
                ret = @as(usize, @intCast(try self.byte_stream.readByte()));
                if (self.little_endian) {
                    ret |= @as(usize, @intCast(try self.byte_stream.readByte())) << 8;
                    ret |= @as(usize, @intCast(try self.byte_stream.readByte())) << 16;
                    ret |= @as(usize, @intCast(try self.byte_stream.readByte())) << 24;
                    ret |= @as(usize, @intCast(try self.byte_stream.readByte())) << 32;
                    ret |= @as(usize, @intCast(try self.byte_stream.readByte())) << 40;
                    ret |= @as(usize, @intCast(try self.byte_stream.readByte())) << 48;
                    ret |= @as(usize, @intCast(try self.byte_stream.readByte())) << 56;
                } else {
                    ret <<= 56;
                    ret |= @as(usize, @intCast(try self.byte_stream.readByte())) << 48;
                    ret |= @as(usize, @intCast(try self.byte_stream.readByte())) << 40;
                    ret |= @as(usize, @intCast(try self.byte_stream.readByte())) << 32;
                    ret |= @as(usize, @intCast(try self.byte_stream.readByte())) << 24;
                    ret |= @as(usize, @intCast(try self.byte_stream.readByte())) << 16;
                    ret |= @as(usize, @intCast(try self.byte_stream.readByte())) << 8;
                    ret |= @as(usize, @intCast(try self.byte_stream.readByte()));
                }
            },
            i64 => {
                ret = @as(i64, @bitCast(@as(u64, @intCast(try self.byte_stream.readByte()))));
                if (self.little_endian) {
                    ret |= @as(i64, @bitCast(@as(u64, @intCast(try self.byte_stream.readByte())))) << 8;
                    ret |= @as(i64, @bitCast(@as(u64, @intCast(try self.byte_stream.readByte())))) << 16;
                    ret |= @as(i64, @bitCast(@as(u64, @intCast(try self.byte_stream.readByte())))) << 24;
                    ret |= @as(i64, @bitCast(@as(u64, @intCast(try self.byte_stream.readByte())))) << 32;
                    ret |= @as(i64, @bitCast(@as(u64, @intCast(try self.byte_stream.readByte())))) << 40;
                    ret |= @as(i64, @bitCast(@as(u64, @intCast(try self.byte_stream.readByte())))) << 48;
                    ret |= @as(i64, @bitCast(@as(u64, @intCast(try self.byte_stream.readByte())))) << 56;
                } else {
                    ret <<= 56;
                    ret |= @as(i64, @bitCast(@as(u64, @intCast(try self.byte_stream.readByte())))) << 48;
                    ret |= @as(i64, @bitCast(@as(u64, @intCast(try self.byte_stream.readByte())))) << 40;
                    ret |= @as(i64, @bitCast(@as(u64, @intCast(try self.byte_stream.readByte())))) << 32;
                    ret |= @as(i64, @bitCast(@as(u64, @intCast(try self.byte_stream.readByte())))) << 24;
                    ret |= @as(i64, @bitCast(@as(u64, @intCast(try self.byte_stream.readByte())))) << 16;
                    ret |= @as(i64, @bitCast(@as(u64, @intCast(try self.byte_stream.readByte())))) << 8;
                    ret |= @as(i64, @bitCast(@as(u64, @intCast(try self.byte_stream.readByte()))));
                }
            },
            f32 => {
                var float_imm: u32 = @as(u32, @bitCast(try self.byte_stream.readByte()));
                if (self.little_endian) {
                    float_imm |= @as(u32, @intCast(try self.byte_stream.readByte())) << 8;
                    float_imm |= @as(u32, @intCast(try self.byte_stream.readByte())) << 16;
                    float_imm |= @as(u32, @intCast(try self.byte_stream.readByte())) << 24;
                } else {
                    float_imm <<= 24;
                    float_imm |= @as(u32, @intCast(try self.byte_stream.readByte())) << 16;
                    float_imm |= @as(u32, @intCast(try self.byte_stream.readByte())) << 8;
                    float_imm |= @as(u32, @intCast(try self.byte_stream.readByte()));
                }
                ret = @as(f32, @floatFromInt(float_imm));
            },
            f64 => {
                var float_imm: u64 = @as(u64, @bitCast(try self.byte_stream.readByte()));
                if (self.little_endian) {
                    float_imm |= @as(u64, @intCast(try self.byte_stream.readByte())) << 8;
                    float_imm |= @as(u64, @intCast(try self.byte_stream.readByte())) << 16;
                    float_imm |= @as(u64, @intCast(try self.byte_stream.readByte())) << 24;
                    float_imm |= @as(u64, @intCast(try self.byte_stream.readByte())) << 32;
                    float_imm |= @as(u64, @intCast(try self.byte_stream.readByte())) << 40;
                    float_imm |= @as(u64, @intCast(try self.byte_stream.readByte())) << 48;
                    float_imm |= @as(u64, @intCast(try self.byte_stream.readByte())) << 56;
                } else {
                    float_imm <<= 56;
                    float_imm |= @as(u64, @intCast(try self.byte_stream.readByte())) << 48;
                    float_imm |= @as(u64, @intCast(try self.byte_stream.readByte())) << 40;
                    float_imm |= @as(u64, @intCast(try self.byte_stream.readByte())) << 32;
                    float_imm |= @as(u64, @intCast(try self.byte_stream.readByte())) << 24;
                    float_imm |= @as(u64, @intCast(try self.byte_stream.readByte())) << 16;
                    float_imm |= @as(u64, @intCast(try self.byte_stream.readByte())) << 8;
                    float_imm |= @as(u64, @intCast(try self.byte_stream.readByte()));
                }
                ret = @as(f64, @floatFromInt(float_imm));
            },
            else => return Error.InvalidArgs,
        }
        return ret;
    }
    pub fn read_bit(self: *Self) Error!u32 {
        var bit: u32 = undefined;
        if (self.next_bit == 0) {
            if (!self.has_bits()) {
                return Error.InvalidRead;
            }
            self.next_byte = try self.byte_stream.readByte();
            if (self.jpeg_filter) {
                while (self.next_byte == 0xFF) {
                    var marker: u8 = try self.byte_stream.peek();
                    while (marker == 0xFF) {
                        _ = try self.byte_stream.readByte();
                        marker = try self.byte_stream.peek();
                    }
                    if (marker == 0x00) {
                        _ = try self.byte_stream.readByte();
                        break;
                    } else if (marker >= 0xD0 and marker <= 0xD7) {
                        COMMON_LOG.info("Found marker 0x{X}\n", .{marker});
                        _ = try self.byte_stream.readByte();
                        self.next_byte = try self.byte_stream.readByte();
                    } else {
                        COMMON_LOG.info("Unexpected marker 0x{X}\n", .{marker});
                        if (marker == 0xD9) {
                            self.byte_stream.index -= 1;
                            return Error.InvalidEOI;
                        }
                        _ = try self.byte_stream.readByte();
                        self.next_byte = try self.byte_stream.readByte();
                    }
                }
            }
        }
        if (self.reverse_bit_order) {
            bit = (self.next_byte >> @as(u5, @intCast(self.next_bit))) & 1;
        } else {
            bit = (self.next_byte >> @as(u5, @intCast(7 - self.next_bit))) & 1;
        }

        self.next_bit = (self.next_bit + 1) % 8;
        return bit;
    }
    pub fn read_bits(self: *Self, length: u32) Error!u32 {
        var bits: u32 = 0;
        for (0..length) |i| {
            const bit = try self.read_bit();
            if (self.reverse_bit_order) {
                bits |= bit << @as(u5, @intCast(i));
            } else {
                bits = (bits << 1) | bit;
            }
        }
        return bits;
    }
    pub fn align_reader(self: *Self) void {
        self.next_bit = 0;
    }
};

/// A utility struct for representing a callback function with an associated context. The struct is parameterized by a data type `DATA_TYPE`, which represents the type of data that will be passed to the callback function when it is called. The struct provides methods for initializing a callback with a specific function and context, and for calling the callback with a given data value.
pub fn Callback(comptime DATA_TYPE: type) type {
    return struct {
        function: *const fn (context: *anyopaque, DATA_TYPE) void,
        context: *anyopaque,
        const Self = @This();
        pub fn init(comptime T: type, function: *const fn (context: *T, DATA_TYPE) void, context: *T) Self {
            return Self{ .function = @ptrCast(function), .context = context };
        }

        pub fn call(callback: Self, data: DATA_TYPE) void {
            return callback.function(callback.context, data);
        }
    };
}

/// A utility struct for representing a callback function that does not take any data as an argument, but still has an associated context. The struct provides methods for initializing the callback with a specific function and context, and for calling the callback without any data.
pub fn CallbackNoData() type {
    return struct {
        function: *const fn (context: *anyopaque) void,
        context: *anyopaque,
        const Self = @This();
        pub fn init(comptime T: type, function: *const fn (context: *T) void, context: *T) Self {
            return Self{ .function = @ptrCast(function), .context = context };
        }

        pub fn call(callback: Self) void {
            return callback.function(callback.context);
        }
    };
}

/// A utility struct for representing a callback function that takes a data argument of type `DATA_TYPE` and returns an error of type `Error`. The struct provides methods for initializing the callback with a specific function and context, and for calling the callback with a given data value while handling any errors that may occur.
pub fn CallbackError(comptime DATA_TYPE: type, comptime Error: type) type {
    return struct {
        function: *const fn (context: *anyopaque, DATA_TYPE) Error!void,
        context: *anyopaque,
        const Self = @This();
        pub fn init(comptime T: type, function: *const fn (context: *T, DATA_TYPE) Error!void, context: *T) Self {
            return Self{ .function = @ptrCast(function), .context = context };
        }

        pub fn call(callback: Self, data: DATA_TYPE) Error!void {
            return try callback.function(callback.context, data);
        }
    };
}
pub fn Point(comptime size: comptime_int, comptime data_type: type) type {
    switch (size) {
        2 => {
            return struct {
                x: data_type = 0,
                y: data_type = 0,
                const Self = @This();
                pub fn eql(lhs: Self, rhs: Self) bool {
                    return lhs.x == rhs.x and lhs.y == rhs.y;
                }
                pub fn distance_squared(lhs: *Self, rhs: Self) f64 {
                    const dx = @as(f64, lhs.x) - @as(f64, rhs.x);
                    const dy = @as(f64, lhs.y) - @as(f64, rhs.y);
                    return dx * dx + dy * dy;
                }
                pub fn lerp(lhs: *Self, rhs: Self, t: f64) Self {
                    const x = @as(data_type, @intFromFloat(COMMON.lerp(@floatFromInt(lhs.x), @floatFromInt(rhs.x), t)));
                    const y = @as(data_type, @intFromFloat(COMMON.lerp(@floatFromInt(lhs.y), @floatFromInt(rhs.y), t)));
                    return .{ .x = x, .y = y };
                }
            };
        },
        3 => {
            return struct {
                x: data_type = 0,
                y: data_type = 0,
                z: data_type = 0,
                const Self = @This();
                pub fn eql(lhs: Self, rhs: Self) bool {
                    return lhs.x == rhs.x and lhs.y == rhs.y and lhs.z == rhs.z;
                }
                pub fn distance_squared(lhs: *Self, rhs: Self) f64 {
                    const dx = @as(f64, lhs.x) - @as(f64, rhs.x);
                    const dy = @as(f64, lhs.y) - @as(f64, rhs.y);
                    const dz = @as(f64, lhs.z) - @as(f64, rhs.z);
                    return dx * dx + dy * dy + dz * dz;
                }
                pub fn lerp(lhs: *Self, rhs: Self, t: f64) Self {
                    const x = @as(data_type, @intFromFloat(COMMON.lerp(@floatFromInt(lhs.x), @floatFromInt(rhs.x), t)));
                    const y = @as(data_type, @intFromFloat(COMMON.lerp(@floatFromInt(lhs.y), @floatFromInt(rhs.y), t)));
                    const z = @as(data_type, @intFromFloat(COMMON.lerp(@floatFromInt(lhs.z), @floatFromInt(rhs.z), t)));
                    return .{ .x = x, .y = y, .z = z };
                }
            };
        },
        else => unreachable,
    }
}

pub const Rectangle = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: u32 = 0,
    height: u32 = 0,
};

var prng: std.Random.Xoshiro256 = undefined;
pub var rand: std.Random = undefined;
/// Initializes a pseudo-random number generator (PRNG) using the Xoshiro256 algorithm. The function generates a random seed by calling the `getrandom` function from the POSIX API, which fills a 64-bit unsigned integer with random bytes. The seed is then used to initialize the PRNG, and the `rand` variable is set to the first random value generated by the PRNG. The function returns an error if there is an issue with generating the random seed or initializing the PRNG.
pub fn gen_rand() std.posix.GetRandomError!void {
    prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    rand = prng.random();
}

test "HUFFMAN_TREE" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var t = try allocator.create(HuffmanTree(u32));
    t.* = try HuffmanTree(u32).init(allocator);
    try t.insert(1, 2, 'A');
    try t.insert(1, 1, 'B');
    try t.insert(0, 3, 'C');
    try t.insert(1, 3, 'D');
    t.deinit();
    allocator.destroy(t);
    if (gpa.deinit() == .leak) {
        std.log.warn("Leaked!\n", .{});
    }
}

test "MATRIX" {
    const size: comptime_int = 3;
    const Matrix = Mat(size, f64);
    var m: Matrix = undefined;
    for (0..size) |i| {
        for (0..size) |j| {
            m.data[i * size + j] = 2;
        }
    }
    m.print();
    var m2: Matrix = undefined;
    for (0..size) |i| {
        for (0..size) |j| {
            m2.data[i * size + j] = 2;
        }
    }
    m2.print();
    var v: Matrix.Vec = undefined;
    for (0..size) |i| {
        v[i] = 2;
    }
    var v_a: [size]f64 = undefined;
    for (0..size) |i| {
        v_a[i] = 2;
    }
    _ = m.mul_v(v);
    _ = m.naive_mul_v(v_a);
    _ = m.mul(m2);
    _ = m.naive_mul(m2);
    const rotate = try Matrix.rotate(.z, 45);
    rotate.print();
    _ = rotate.mul_v(.{ 5, 5, 1 });
    _ = try Matrix.vectorize(.{ 2, 4 });
    const scale = try Mat(4, f64).scale(5);
    scale.print();
}

test "MATRIX mult" {
    const size: comptime_int = 128;
    const Matrix = Mat(size, f64);
    var m: Matrix = Matrix{};
    m.fill_x(0, 2);
    m.print();
    var m2: Matrix = Matrix{};
    m2.fill_x(0, 2);
    m2.print();
}

test "Transpose" {
    const size: comptime_int = 3;
    const Matrix = Mat(size, f64);
    var m = Matrix.init(.{ 1, 2, 3, 4, 5, 6, 7, 8, 9 });
    m.print();
    m.transpose();
    m.print();
}

test "colored hello world" {
    std.debug.print(ColoredTerminal.colored_format("hello world\n", .blue), .{});
}
