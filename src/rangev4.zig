const std = @import("std");
const root = @import("root.zig");
const builtin = @import("builtin");
const native_endian = builtin.cpu.arch.endian();
const IPv4 = root.IPv4;

const Self = @This();

start: @Vector(4, u8),
end: @Vector(4, u8),

pub fn parse(range: []const u8) !Self {
    var digits: [4][]const u8 = undefined;
    var it = std.mem.splitScalar(u8, range, '.');
    var count: usize = 0;
    while (it.next()) |entry| {
        digits[count] = entry;
        count += 1;
        if (count > 4) return error.InvalidRangev4;
    }
    if (count != 4) return error.InvalidRangev4;

    var start: [4]u8 = undefined;
    var end: [4]u8 = undefined;

    count = 0;
    for (digits) |d| {
        var dit = std.mem.splitScalar(u8, d, '-');
        const a = dit.next();
        const b = dit.next();
        var an: u8 = undefined;
        var bn: u8 = undefined;

        if (a) |v| {
            an = std.fmt.parseInt(u8, v, 0) catch return error.InvalidRangev4;
        } else {
            return error.InvalidRangev4;
        }

        if (b) |v| {
            bn = std.fmt.parseInt(u8, v, 0) catch return error.InvalidRangev4;
            if (dit.next() != null) return error.InvalidRangev4;
        } else {
            bn = an;
        }

        start[count] = @min(an, bn);
        end[count] = @max(an, bn);

        count += 1;
    }

    return .{ .start = start, .end = end };
}

pub fn contains(self: Self, ip: IPv4) bool {
    const tmp: [4]u8 = std.mem.asBytes(switch (native_endian) {
        .big => &ip.addr,
        .little => blk: {
            var addr = @byteSwap(ip.addr);
            break :blk &addr;
        },
    }).*;
    const vec: @Vector(4, u8) = tmp;
    return @reduce(.And, vec <= self.end) and @reduce(.And, vec >= self.start);
}

pub fn len(self: Self) u33 {
    var ret: u33 = 1;
    for (@as([4]u8, self.start), @as([4]u8, self.end)) |m, M| {
        var diff: u9 = M - m;
        diff += 1;
        ret *= diff;
    }
    return ret;
}

pub fn min(self: Self) IPv4 {
    var tmp: [4]u8 = self.start;
    return .{
        .addr = switch (native_endian) {
            .big => std.mem.bytesToValue(u32, &tmp),
            .little => blk: {
                const i = std.mem.bytesToValue(u32, &tmp);
                break :blk @byteSwap(i);
            },
        },
    };
}

pub fn max(self: Self) IPv4 {
    var tmp: [4]u8 = self.end;
    return .{
        .addr = switch (native_endian) {
            .big => std.mem.bytesToValue(u32, &tmp),
            .little => blk: {
                const i = std.mem.bytesToValue(u32, &tmp);
                break :blk @byteSwap(i);
            },
        },
    };
}

test "test parse" {
    try std.testing.expectError(error.InvalidRangev4, Self.parse("0.0.0.0-"));
    try std.testing.expectError(error.InvalidRangev4, Self.parse("0.0.0.-"));
    try std.testing.expectError(error.InvalidRangev4, Self.parse("0.0.0.0-1-2"));
    var range = try Self.parse("0.0.0.0");
    try std.testing.expectEqual([_]u8{ 0, 0, 0, 0 }, range.start);
    try std.testing.expectEqual([_]u8{ 0, 0, 0, 0 }, range.end);
    range = try Self.parse("0-255.0.0.0-127");
    try std.testing.expectEqual([_]u8{ 0, 0, 0, 0 }, range.start);
    try std.testing.expectEqual([_]u8{ 255, 0, 0, 127 }, range.end);
    range = try Self.parse("255-0.0.0.127-0");
    try std.testing.expectEqual([_]u8{ 0, 0, 0, 0 }, range.start);
    try std.testing.expectEqual([_]u8{ 255, 0, 0, 127 }, range.end);
}

test "test contains" {
    var range = try Self.parse("0.0.0.0");
    try std.testing.expectEqual(true, range.contains(try IPv4.parse("0.0.0.0")));
    try std.testing.expectEqual(false, range.contains(try IPv4.parse("0.0.0.1")));

    range = try Self.parse("0-254.0.0-254.0");
    try std.testing.expectEqual(true, range.contains(try IPv4.parse("0.0.0.0")));
    try std.testing.expectEqual(true, range.contains(try IPv4.parse("254.0.0.0")));
    try std.testing.expectEqual(true, range.contains(try IPv4.parse("0.0.254.0")));
    try std.testing.expectEqual(true, range.contains(try IPv4.parse("254.0.254.0")));
    try std.testing.expectEqual(false, range.contains(try IPv4.parse("254.1.254.0")));
    try std.testing.expectEqual(false, range.contains(try IPv4.parse("255.0.254.0")));
    try std.testing.expectEqual(false, range.contains(try IPv4.parse("255.0.0.0")));
    try std.testing.expectEqual(false, range.contains(try IPv4.parse("0.1.0.0")));
}

test "test len" {
    var range = try Self.parse("0.0.0.0-255");
    try std.testing.expectEqual(256, range.len());
    range = try Self.parse("0-255.0.0.1-255");
    try std.testing.expectEqual(256 * 255, range.len());
}

test "test min max" {
    var range = try Self.parse("1-255.0.0.255");
    try std.testing.expectEqual(try IPv4.parse("1.0.0.255"), range.min());
    try std.testing.expectEqual(try IPv4.parse("255.0.0.255"), range.max());
}
