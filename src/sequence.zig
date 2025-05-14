const std = @import("std");
const root = @import("root.zig");
const Self = @This();

const Type = enum {
    cidrv4,
    cidrv6,
};

const Val = union(Type) {
    cidrv4: root.IPv4.CIDR,
    cidrv6: root.IPv6.CIDR,
};

v: Val,

fn optParse(comptime T: type, s: []const u8) ?T {
    return T.parse(s) catch {
        return null;
    };
}

pub fn parse(seq: []const u8) !@This() {
    const ts = comptime [_]type{
        root.IPv4.CIDR,
        root.IPv6.CIDR,
    };

    inline for (ts) |t| {
        if (optParse(t, seq)) |v| {
            switch (t) {
                root.IPv4.CIDR => {
                    return .{ .v = .{ .cidrv4 = v } };
                },
                root.IPv6.CIDR => {
                    return .{ .v = .{ .cidrv6 = v } };
                },
                else => unreachable,
            }
        }
    }

    return error.InvalidSequence;
}

test "test parse" {
    var seq = try Self.parse("0/0");
    try std.testing.expect(@as(Type, seq.v) == Type.cidrv4);
    seq = try Self.parse("::/0");
    try std.testing.expect(@as(Type, seq.v) == Type.cidrv6);
}
