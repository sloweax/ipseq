const std = @import("std");
const root = @import("root.zig");
const CIDRv4 = root.IPv4.CIDR;
const IPv4 = root.IPv4;

test "test parse" {
    var cidr = try CIDRv4.parse("192.168.10.0/24");
    try std.testing.expect(cidr.bits() == 24);
    try std.testing.expect(cidr.mask == 0xffffff00);
    try std.testing.expect(cidr.ipv4.addr == 0xc0a80a00);
    cidr = try CIDRv4.parse("192.168.10.1/24");
    try std.testing.expect(cidr.bits() == 24);
    try std.testing.expect(cidr.mask == 0xffffff00);
    try std.testing.expect(cidr.ipv4.addr == 0xc0a80a01);

    try std.testing.expectError(error.InvalidCIDRv4, CIDRv4.parse("192.168.10.0/33"));
    try std.testing.expectError(error.InvalidIPv4, CIDRv4.parse("192.168.10.p/24"));
}

test "test min max" {
    var cidr = try CIDRv4.parse("192.168.10.0/24");
    try std.testing.expect(cidr.min().eql(try IPv4.parse("192.168.10.0")));
    try std.testing.expect(cidr.max().eql(try IPv4.parse("192.168.10.255")));
    cidr = try CIDRv4.parse("0.0.0.0/0");
    try std.testing.expect(cidr.min().eql(try IPv4.parse("0.0.0.0")));
    try std.testing.expect(cidr.max().eql(try IPv4.parse("255.255.255.255")));
    cidr = try CIDRv4.parse("192.168.10.1/24");
    try std.testing.expect(cidr.min().eql(try IPv4.parse("192.168.10.1")));
    try std.testing.expect(cidr.max().eql(try IPv4.parse("192.168.10.255")));
    cidr = try CIDRv4.parse("0.0.0.0/1");
    try std.testing.expect(cidr.max().eql(try IPv4.parse("127.255.255.255")));
}

test "test contains" {
    var cidr = try CIDRv4.parse("192.168.10.0/24");
    try std.testing.expect(cidr.contains(try IPv4.parse("192.168.10.0")));
    try std.testing.expect(cidr.contains(try IPv4.parse("192.168.10.255")));
    try std.testing.expect(!cidr.contains(try IPv4.parse("192.168.11.0")));
    try std.testing.expect(!cidr.contains(try IPv4.parse("192.168.9.0")));
    cidr = try CIDRv4.parse("192.168.10.1/24");
    try std.testing.expect(!cidr.contains(try IPv4.parse("192.168.10.0")));
    try std.testing.expect(cidr.contains(try IPv4.parse("192.168.10.1")));
    try std.testing.expect(cidr.contains(try IPv4.parse("192.168.10.255")));
    try std.testing.expect(!cidr.contains(try IPv4.parse("192.168.11.0")));
    try std.testing.expect(!cidr.contains(try IPv4.parse("192.168.9.0")));
}
