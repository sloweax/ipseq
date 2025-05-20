const std = @import("std");
const root = @import("root.zig");
const CIDRv6 = root.IPv6.CIDR;
const IPv6 = root.IPv6;

test "test parse" {
    var cidr = try CIDRv6.parse("1:2:3:4::/64");
    try std.testing.expect(cidr.bits() == 64);
    try std.testing.expect(cidr.mask == 0xffffffffffffffff0000000000000000);
    try std.testing.expect(cidr.ipv6.addr == 0x00010002000300040000000000000000);

    try std.testing.expectError(error.InvalidCIDRv6, CIDRv6.parse("::/129"));
}

test "test min max" {
    var cidr = try CIDRv6.parse("1:2:3:4::/64");
    try std.testing.expect(cidr.min().eql(try IPv6.parse("1:2:3:4::")));
    try std.testing.expect(cidr.max().eql(try IPv6.parse("1:2:3:4:ffff:ffff:ffff:ffff")));

    cidr = try CIDRv6.parse("::/0");
    try std.testing.expect(cidr.min().eql(try IPv6.parse("::")));
    try std.testing.expect(cidr.max().eql(try IPv6.parse("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff")));

    cidr = try CIDRv6.parse("1:2:3:4::1/64");
    try std.testing.expect(cidr.min().eql(try IPv6.parse("1:2:3:4::1")));
    try std.testing.expect(cidr.max().eql(try IPv6.parse("1:2:3:4:ffff:ffff:ffff:ffff")));
}
