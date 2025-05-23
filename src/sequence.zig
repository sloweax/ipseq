const std = @import("std");
const root = @import("root.zig");
const Self = @This();

v: union(enum) {
    cidrv4: root.IPv4.CIDR,
    cidrv6: root.IPv6.CIDR,
    ipv4: root.IPv4,
    ipv6: root.IPv6,
    rangev4: root.IPv4.Range,
    rangev6: root.IPv6.Range,
},

fn optParse(comptime T: type, s: []const u8) ?T {
    return T.parse(s) catch {
        return null;
    };
}

pub fn parse(seq: []const u8) !@This() {
    const ts = comptime [_]type{
        root.IPv4,
        root.IPv4.CIDR,
        root.IPv4.Range,
        root.IPv6,
        root.IPv6.CIDR,
        root.IPv6.Range,
    };

    inline for (ts) |t| {
        if (optParse(t, seq)) |v| {
            switch (t) {
                root.IPv4 => {
                    return .{ .v = .{ .ipv4 = v } };
                },
                root.IPv6 => {
                    return .{ .v = .{ .ipv6 = v } };
                },
                root.IPv4.CIDR => {
                    return .{ .v = .{ .cidrv4 = v } };
                },
                root.IPv6.CIDR => {
                    return .{ .v = .{ .cidrv6 = v } };
                },
                root.IPv4.Range => {
                    return .{ .v = .{ .rangev4 = v } };
                },
                root.IPv6.Range => {
                    return .{ .v = .{ .rangev6 = v } };
                },
                else => unreachable,
            }
        }
    }

    return error.InvalidSequence;
}

pub fn len(self: Self) u129 {
    switch (self.v) {
        .ipv4, .ipv6 => {
            return 1;
        },
        .cidrv4 => |v| {
            return v.len();
        },
        .cidrv6 => |v| {
            return v.len();
        },
        .rangev4 => |v| {
            return v.len();
        },
        .rangev6 => |v| {
            return v.len();
        },
    }
}

test "test parse" {
    var seq = try Self.parse("0/0");
    try std.testing.expectEqual("cidrv4", @tagName(seq.v));
    seq = try Self.parse("::/0");
    try std.testing.expectEqual("cidrv6", @tagName(seq.v));
}

test "test len" {
    try std.testing.expect((try Self.parse("0")).len() == 1);
    try std.testing.expect((try Self.parse("::")).len() == 1);
    try std.testing.expect((try Self.parse("0/24")).len() == 256);
    try std.testing.expect((try Self.parse("0/0")).len() == 4294967296);
    try std.testing.expect((try Self.parse("::/0")).len() == 340282366920938463463374607431768211456);
}
