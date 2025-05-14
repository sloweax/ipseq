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

test "test iterator" {
    var cidr = try CIDRv4.parse("192.168.0.8/32");
    var it = cidr.iterator();
    try std.testing.expect((try IPv4.parse("192.168.0.8")).eqlo(it.next()));
    try std.testing.expect(it.next() == null);

    cidr = try CIDRv4.parse("192.168.0.8/31");
    it = cidr.iterator();
    try std.testing.expect((try IPv4.parse("192.168.0.8")).eqlo(it.next()));
    try std.testing.expect((try IPv4.parse("192.168.0.9")).eqlo(it.next()));
    try std.testing.expect(it.next() == null);

    cidr = try CIDRv4.parse("0.0.0.0/0");
    it = cidr.iterator();
    try std.testing.expect((try IPv4.parse("0.0.0.0")).eqlo(it.next()));
    try std.testing.expect((try IPv4.parse("0.0.0.1")).eqlo(it.next()));
    it.cur = std.math.maxInt(u32);
    try std.testing.expect((try IPv4.parse("255.255.255.255")).eqlo(it.next()));
    try std.testing.expect(it.next() == null);

    cidr = try CIDRv4.parse("192.168.0.0/16");
    it = cidr.iterator();
    it.cur += 255;
    try std.testing.expect((try IPv4.parse("192.168.0.255")).eqlo(it.next()));
    try std.testing.expect((try IPv4.parse("192.168.1.0")).eqlo(it.next()));
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
