const std = @import("std");
const root = @import("root.zig");
const IPv6 = root.IPv6;

ipv6: IPv6,
mask: u128,

const Self = @This();

pub fn min(self: Self) IPv6 {
    return self.ipv6;
}

pub fn max(self: Self) IPv6 {
    const b = self.bits();
    return switch (b) {
        0 => .{ .addr = std.math.maxInt(u128) },
        else => .{ .addr = self.ipv6.addr | (std.math.pow(u128, 2, 128 - b) - 1) },
    };
}

pub fn contains(self: Self, ipv6: IPv6) bool {
    const a = self.ipv6.addr & self.mask;
    const b = ipv6.addr & self.mask;
    if (a == b) return ipv6.addr >= self.ipv6.addr;
    return false;
}

pub fn parse(cidr: []const u8) !Self {
    var it = std.mem.splitAny(u8, cidr, "/");
    const addr = it.next();
    const mask = it.next();
    if (addr == null) return error.InvalidCIDRv6;
    if (mask == null) return error.InvalidCIDRv6;
    if (it.next() != null) return error.InvalidCIDRv6;
    const a = try IPv6.parse(addr.?);
    const b = try std.fmt.parseInt(u128, mask.?, 0);
    if (b > 128) return error.InvalidCIDRv6;
    var m: u128 = std.math.maxInt(u128);
    m = std.math.shl(u128, m, 128 - b);
    return .{ .ipv6 = a, .mask = m };
}

pub fn bits(self: Self) u8 {
    return @popCount(self.mask);
}

pub fn len(self: Self) u129 {
    return @as(u129, self.max().addr - self.min().addr) + 1;
}

test "test len" {
    var cidr = try Self.parse("1:2:3:4::/64");
    try std.testing.expectEqual(std.math.pow(u129, 2, 64), cidr.len());
    cidr = try Self.parse("::/0");
    try std.testing.expectEqual(std.math.pow(u129, 2, 128), cidr.len());
    cidr = try Self.parse("::/1");
    try std.testing.expectEqual(std.math.pow(u129, 2, 127), cidr.len());
}

test "test parse" {
    var cidr = try Self.parse("1:2:3:4::/64");
    try std.testing.expect(cidr.bits() == 64);
    try std.testing.expect(cidr.mask == 0xffffffffffffffff0000000000000000);
    try std.testing.expect(cidr.ipv6.addr == 0x00010002000300040000000000000000);

    try std.testing.expectError(error.InvalidCIDRv6, Self.parse("::/129"));
}

test "test min max" {
    var cidr = try Self.parse("1:2:3:4::/64");
    try std.testing.expect(cidr.min().eql(try IPv6.parse("1:2:3:4::")));
    try std.testing.expect(cidr.max().eql(try IPv6.parse("1:2:3:4:ffff:ffff:ffff:ffff")));

    cidr = try Self.parse("::/0");
    try std.testing.expect(cidr.min().eql(try IPv6.parse("::")));
    try std.testing.expect(cidr.max().eql(try IPv6.parse("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff")));

    cidr = try Self.parse("1:2:3:4::1/64");
    try std.testing.expect(cidr.min().eql(try IPv6.parse("1:2:3:4::1")));
    try std.testing.expect(cidr.max().eql(try IPv6.parse("1:2:3:4:ffff:ffff:ffff:ffff")));
}
