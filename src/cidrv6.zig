const std = @import("std");
const root = @import("root.zig");
const IPv6 = root.IPv6;

ipv6: IPv6,
mask: u128,

const Self = @This();

const Iterator = struct {
    cidr: Self,
    end: u128,
    cur: u128 = 0,
    eof: bool = false,

    pub fn next(self: *@This()) ?IPv6 {
        if (self.eof) return null;
        var tmp = self.cidr.ipv6.addr & self.cidr.mask;
        tmp |= self.cur;
        if (self.cur >= self.end) {
            self.eof = true;
        } else {
            self.cur += 1;
        }
        return .{ .addr = tmp };
    }
};

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

pub fn iterator(self: Self) Iterator {
    return .{
        .cidr = self,
        .end = self.max().addr & (~self.mask),
        .cur = self.min().addr & (~self.mask),
    };
}

pub fn bits(self: Self) u8 {
    return @popCount(self.mask);
}
