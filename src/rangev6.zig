const std = @import("std");
const root = @import("root.zig");
const builtin = @import("builtin");
const native_endian = builtin.cpu.arch.endian();
const IPv6 = root.IPv6;

const Self = @This();

start: @Vector(8, u16),
end: @Vector(8, u16),

pub fn parse(range: []const u8) !Self {
    var digits_count: usize = 0;
    var digits: [8][]const u8 = undefined;
    if (std.mem.count(u8, range, ":::") > 0) return error.InvalidRangev6;
    switch (std.mem.count(u8, range, "::")) {
        0 => {
            var count: usize = 0;
            var it = std.mem.splitScalar(u8, range, ':');
            while (it.next()) |entry| {
                count += 1;
                if (count > 8) return error.InvalidRangev6;
                digits[digits_count] = entry;
                digits_count += 1;
            }
            if (count != 8) return error.InvalidRangev6;
        },
        1 => {
            var it = std.mem.splitSequence(u8, range, "::");
            const l = it.next().?;
            const r = it.next().?;

            var lc = std.mem.count(u8, l, ":");
            var rc = std.mem.count(u8, r, ":");
            if ((lc + rc) >= 6) return error.InvalidRangev6;
            if (lc > 0) lc += 1;
            if (rc > 0) rc += 1;
            if (lc == 0 and l.len > 0) lc += 1;
            if (rc == 0 and r.len > 0) rc += 1;

            if (lc > 0) {
                var lit = std.mem.splitScalar(u8, l, ':');
                while (lit.next()) |entry| {
                    digits[digits_count] = entry;
                    digits_count += 1;
                }
            }

            var cnt: usize = 8 - (lc + rc);
            while (cnt > 0) {
                digits[digits_count] = "0";
                digits_count += 1;
                cnt -= 1;
            }

            if (rc > 0) {
                var rit = std.mem.splitScalar(u8, r, ':');
                while (rit.next()) |entry| {
                    digits[digits_count] = entry;
                    digits_count += 1;
                }
            }
        },
        else => return error.InvalidRangev6,
    }

    var start: [8]u16 = undefined;
    var end: [8]u16 = undefined;

    for (digits, 0..) |d, i| {
        var dit = std.mem.splitScalar(u8, d, '-');
        const a = dit.next();
        const b = dit.next();
        var an: u16 = undefined;
        var bn: u16 = undefined;
        if (a) |v| {
            an = std.fmt.parseInt(u16, v, 16) catch return error.InvalidRangev6;
        } else {
            return error.InvalidRangev6;
        }

        if (b) |v| {
            bn = std.fmt.parseInt(u16, v, 16) catch return error.InvalidRangev6;
            if (dit.next() != null) return error.InvalidRangev6;
        } else {
            bn = an;
        }

        start[i] = @min(an, bn);
        end[i] = @max(an, bn);
    }

    return .{ .start = start, .end = end };
}

pub fn len(self: Self) u129 {
    var ret: u129 = 1;
    for (@as([8]u16, self.start), @as([8]u16, self.end)) |m, M| {
        var diff: u17 = M - m;
        diff += 1;
        ret *= diff;
    }
    return ret;
}

pub fn contains(self: Self, ip: IPv6) bool {
    var arr: [8]u16 = undefined;
    var tmp = ip.addr;
    for (0..8) |i| {
        arr[7 - i] = @truncate(tmp);
        tmp >>= 16;
    }
    const vec: @Vector(8, u16) = arr;
    return @reduce(.And, vec <= self.end) and @reduce(.And, vec >= self.start);
}

pub fn min(self: Self) IPv6 {
    var r: u128 = 0;
    for (@as([8]u16, self.start)) |e| {
        r *= 65536;
        r += e;
    }
    return .{ .addr = r };
}

pub fn max(self: Self) IPv6 {
    var r: u128 = 0;
    for (@as([8]u16, self.end)) |e| {
        r *= 65536;
        r += e;
    }
    return .{ .addr = r };
}

test "test parse" {
    try std.testing.expectError(error.InvalidRangev6, Self.parse(":-:"));
    try std.testing.expectError(error.InvalidRangev6, Self.parse("0-1:"));
    try std.testing.expectError(error.InvalidRangev6, Self.parse("0-1::0-1-0"));
    var range = try Self.parse("::");
    try std.testing.expectEqual([_]u16{ 0, 0, 0, 0, 0, 0, 0, 0 }, range.start);
    try std.testing.expectEqual([_]u16{ 0, 0, 0, 0, 0, 0, 0, 0 }, range.end);
    range = try Self.parse("::0-1");
    try std.testing.expectEqual([_]u16{ 0, 0, 0, 0, 0, 0, 0, 0 }, range.start);
    try std.testing.expectEqual([_]u16{ 0, 0, 0, 0, 0, 0, 0, 1 }, range.end);
    range = try Self.parse("1:2::0-1");
    try std.testing.expectEqual([_]u16{ 1, 2, 0, 0, 0, 0, 0, 0 }, range.start);
    try std.testing.expectEqual([_]u16{ 1, 2, 0, 0, 0, 0, 0, 1 }, range.end);
    range = try Self.parse("1-ffff:2-fffe::0-1");
    try std.testing.expectEqual([_]u16{ 1, 2, 0, 0, 0, 0, 0, 0 }, range.start);
    try std.testing.expectEqual([_]u16{ 0xffff, 0xfffe, 0, 0, 0, 0, 0, 1 }, range.end);
}

test "test contains" {
    var range = try Self.parse("::");
    try std.testing.expectEqual(true, range.contains(try IPv6.parse("::")));
    try std.testing.expectEqual(false, range.contains(try IPv6.parse("::1")));

    range = try Self.parse("0-ffff::0-fffe:0");
    try std.testing.expectEqual(true, range.contains(try IPv6.parse("::")));
    try std.testing.expectEqual(true, range.contains(try IPv6.parse("ffff::")));
    try std.testing.expectEqual(true, range.contains(try IPv6.parse("::fffe:0")));
    try std.testing.expectEqual(true, range.contains(try IPv6.parse("ffff::fffe:0")));
    try std.testing.expectEqual(false, range.contains(try IPv6.parse("ffff:1::fffe:0")));
    try std.testing.expectEqual(false, range.contains(try IPv6.parse("ffff::ffff:0")));
    try std.testing.expectEqual(false, range.contains(try IPv6.parse("0:1::")));
}
