const std = @import("std");
const CIDRv4 = @import("cidrv4.zig");

test "test parse" {
    var cidr = try CIDRv4.parse("192.168.10.0/24");
    try std.testing.expect(cidr.bits() == 24);
    try std.testing.expect(cidr.mask == 0xffffff00);
    try std.testing.expect(cidr.ipv4 == 0xc0a80a00);
    cidr = try CIDRv4.parse("192.168.10.1/24");
    try std.testing.expect(cidr.bits() == 24);
    try std.testing.expect(cidr.mask == 0xffffff00);
    try std.testing.expect(cidr.ipv4 == 0xc0a80a01);

    try std.testing.expectError(error.InvalidCIDRv4, CIDRv4.parse("192.168.10.0/33"));
    try std.testing.expectError(error.InvalidIPv4, CIDRv4.parse("192.168.10.p/24"));
}

test "test iterator" {
    var cidr = try CIDRv4.parse("192.168.0.8/32");
    var it = cidr.iterator();
    try std.testing.expect(it.next() == try CIDRv4.parseIPv4("192.168.0.8"));
    try std.testing.expect(it.next() == null);

    cidr = try CIDRv4.parse("192.168.0.8/31");
    it = cidr.iterator();
    try std.testing.expect(it.next() == try CIDRv4.parseIPv4("192.168.0.8"));
    try std.testing.expect(it.next() == try CIDRv4.parseIPv4("192.168.0.9"));
    try std.testing.expect(it.next() == null);

    cidr = try CIDRv4.parse("0.0.0.0/0");
    it = cidr.iterator();
    try std.testing.expect(it.next() == try CIDRv4.parseIPv4("0.0.0.0"));
    try std.testing.expect(it.next() == try CIDRv4.parseIPv4("0.0.0.1"));
    it.cur = std.math.maxInt(u32);
    try std.testing.expect(it.next() == try CIDRv4.parseIPv4("255.255.255.255"));
    try std.testing.expect(it.next() == null);

    cidr = try CIDRv4.parse("192.168.0.0/16");
    it = cidr.iterator();
    it.cur += 255;
    try std.testing.expect(it.next() == try CIDRv4.parseIPv4("192.168.0.255"));
    try std.testing.expect(it.next() == try CIDRv4.parseIPv4("192.168.1.0"));
}

test "test min max" {
    var cidr = try CIDRv4.parse("192.168.10.0/24");
    try std.testing.expect(cidr.min() == try CIDRv4.parseIPv4("192.168.10.0"));
    try std.testing.expect(cidr.max() == try CIDRv4.parseIPv4("192.168.10.255"));
    cidr = try CIDRv4.parse("0.0.0.0/0");
    try std.testing.expect(cidr.min() == try CIDRv4.parseIPv4("0.0.0.0"));
    try std.testing.expect(cidr.max() == try CIDRv4.parseIPv4("255.255.255.255"));
    cidr = try CIDRv4.parse("192.168.10.1/24");
    try std.testing.expect(cidr.min() == try CIDRv4.parseIPv4("192.168.10.1"));
    try std.testing.expect(cidr.max() == try CIDRv4.parseIPv4("192.168.10.255"));
    cidr = try CIDRv4.parse("0.0.0.0/1");
    try std.testing.expect(cidr.max() == try CIDRv4.parseIPv4("127.255.255.255"));
}

test "test contains" {
    var cidr = try CIDRv4.parse("192.168.10.0/24");
    try std.testing.expect(cidr.contains(try CIDRv4.parseIPv4("192.168.10.0")));
    try std.testing.expect(cidr.contains(try CIDRv4.parseIPv4("192.168.10.255")));
    try std.testing.expect(!cidr.contains(try CIDRv4.parseIPv4("192.168.11.0")));
    try std.testing.expect(!cidr.contains(try CIDRv4.parseIPv4("192.168.9.0")));
    cidr = try CIDRv4.parse("192.168.10.1/24");
    try std.testing.expect(!cidr.contains(try CIDRv4.parseIPv4("192.168.10.0")));
    try std.testing.expect(cidr.contains(try CIDRv4.parseIPv4("192.168.10.1")));
    try std.testing.expect(cidr.contains(try CIDRv4.parseIPv4("192.168.10.255")));
    try std.testing.expect(!cidr.contains(try CIDRv4.parseIPv4("192.168.11.0")));
    try std.testing.expect(!cidr.contains(try CIDRv4.parseIPv4("192.168.9.0")));
}
