const std = @import("std");
const Self = @This();

addr: u128,

pub fn parse(ip: []const u8) !Self {
    if (std.mem.count(u8, ip, ":::") > 0) return error.InvalidIPv6;
    switch (std.mem.count(u8, ip, "::")) {
        0 => {
            var count: usize = 0;
            var it = std.mem.splitScalar(u8, ip, ':');
            var r: u128 = 0;
            while (it.next()) |entry| {
                count += 1;
                if (count > 8) return error.InvalidIPv6;
                const tmp = std.fmt.parseInt(u16, entry, 16) catch {
                    return error.InvalidIPv6;
                };
                r *= 65536;
                r += tmp;
            }
            if (count != 8) return error.InvalidIPv6;
            return .{ .addr = r };
        },
        1 => {
            var ret: u128 = 0;
            var it = std.mem.splitSequence(u8, ip, "::");
            const l = it.next().?;
            const r = it.next().?;

            var lc = std.mem.count(u8, l, ":");
            var rc = std.mem.count(u8, r, ":");
            if ((lc + rc) >= 6) return error.InvalidIPv6;
            if (lc > 0) lc += 1;
            if (rc > 0) rc += 1;
            if (lc == 0 and l.len > 0) lc += 1;
            if (rc == 0 and r.len > 0) rc += 1;

            if (lc > 0) {
                var lit = std.mem.splitScalar(u8, l, ':');
                while (lit.next()) |entry| {
                    const tmp = std.fmt.parseInt(u16, entry, 16) catch {
                        return error.InvalidIPv6;
                    };
                    ret *= 65536;
                    ret += tmp;
                }
            }

            var cnt: usize = 8 - (lc + rc);
            while (cnt > 0) {
                ret *= 65536;
                cnt -= 1;
            }

            if (rc > 0) {
                var rit = std.mem.splitScalar(u8, r, ':');
                while (rit.next()) |entry| {
                    const tmp = std.fmt.parseInt(u16, entry, 16) catch {
                        return error.InvalidIPv6;
                    };
                    ret *= 65536;
                    ret += tmp;
                }
            }

            return .{ .addr = ret };
        },
        else => return error.InvalidIPv6,
    }
}

pub fn eql(a: Self, b: Self) bool {
    return a.addr == b.addr;
}

pub fn eqlo(a: Self, b: ?Self) bool {
    if (b) |c| {
        return a.eql(c);
    }
    return false;
}

test "test parse" {
    try std.testing.expectError(error.InvalidIPv6, Self.parse("0"));
    try std.testing.expectError(error.InvalidIPv6, Self.parse("a"));
    try std.testing.expectError(error.InvalidIPv6, Self.parse("aaaa:aaaa:aaaa:aaaa:bbbb:bbbb:bbbb"));
    try std.testing.expectError(error.InvalidIPv6, Self.parse("aaaa:aaaa:aaaa:aaaa:bbbb:bbbb:bbbb:"));
    try std.testing.expectError(error.InvalidIPv6, Self.parse("1:2:3:4:5::6:7:8"));

    try std.testing.expect((try Self.parse("aacc:aaaa:aaaa:aaaa:bbbb:bbbb:b:cbbc")).addr == 0xaaccaaaaaaaaaaaabbbbbbbb000bcbbc);
    try std.testing.expect((try Self.parse("aacc:aaaa:aaaa:aaaa:bbbb::cbbc")).addr == 0xaaccaaaaaaaaaaaabbbb00000000cbbc);

    try std.testing.expect((try Self.parse("::aabb")).addr == 0xaabb);
    try std.testing.expect((try Self.parse("::ab")).addr == 0xab);
    try std.testing.expect((try Self.parse("::aabb:aabb")).addr == 0xaabbaabb);
    try std.testing.expect((try Self.parse("::aa:aa")).addr == 0x00aa00aa);

    try std.testing.expect((try Self.parse("aabb::")).addr == 0xaabb0000000000000000000000000000);
    try std.testing.expect((try Self.parse("ab::")).addr == 0x00ab0000000000000000000000000000);
    try std.testing.expect((try Self.parse("aabb:aabb::")).addr == 0xaabbaabb000000000000000000000000);
    try std.testing.expect((try Self.parse("aa:aa::")).addr == 0x00aa00aa000000000000000000000000);

    try std.testing.expect((try Self.parse("aabb:aabb::1")).addr == 0xaabbaabb000000000000000000000001);
    try std.testing.expect((try Self.parse("aa:aa::1")).addr == 0x00aa00aa000000000000000000000001);

    try std.testing.expect((try Self.parse("1::aabb:aabb")).addr == 0x000100000000000000000000aabbaabb);
    try std.testing.expect((try Self.parse("1::aa:aa")).addr == 0x00010000000000000000000000aa00aa);

    try std.testing.expect((try Self.parse("aabb::aabb")).addr == 0xaabb000000000000000000000000aabb);
    try std.testing.expect((try Self.parse("ab::ab")).addr == 0x00ab00000000000000000000000000ab);
    try std.testing.expect((try Self.parse("aabb:aabb::aabb:aabb")).addr == 0xaabbaabb0000000000000000aabbaabb);
    try std.testing.expect((try Self.parse("aa:aa::aa:aa")).addr == 0x00aa00aa000000000000000000aa00aa);

    try std.testing.expect((try Self.parse("::")).addr == 0);
    try std.testing.expect((try Self.parse("0::")).addr == 0);
    try std.testing.expect((try Self.parse("::0")).addr == 0);
}
