const std = @import("std");

//TODO port over util functions here, more complex structs in seperate files that then get exposed here
pub const StringKeyMap = @import("string_key_map.zig").StringKeyMap;
pub const Graph = @import("graph.zig");
pub const Mat = @import("matrix.zig").Mat;
pub const Colors = @import("colors.zig").Colors;

var timer: std.time.Timer = undefined;
pub fn timer_start() std.time.Timer.Error!void {
    timer = try std.time.Timer.start();
}

pub fn timer_end() void {
    std.log.debug("{d} s elapsed.\n", .{@as(f64, @floatFromInt(timer.read())) / 1000000000.0});
    timer.reset();
}

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
};

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

// Small utility struct that gives basic byte by byte reading of a file after its been loaded into memory
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
                        _ = try self.byte_stream.readByte();
                        self.next_byte = try self.byte_stream.readByte();
                    } else {
                        return Error.InvalidRead;
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
