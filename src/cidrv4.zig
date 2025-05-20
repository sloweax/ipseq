const std = @import("std");
const root = @import("root.zig");
const IPv4 = root.IPv4;

ipv4: IPv4,
mask: u32,

const Self = @This();

pub fn min(self: Self) IPv4 {
    return self.ipv4;
}

pub fn max(self: Self) IPv4 {
    const b = self.bits();
    return switch (b) {
        0 => .{ .addr = std.math.maxInt(u32) },
        else => .{ .addr = self.ipv4.addr | (std.math.pow(u32, 2, 32 - b) - 1) },
    };
}

pub fn contains(self: Self, ipv4: IPv4) bool {
    const a = self.ipv4.addr & self.mask;
    const b = ipv4.addr & self.mask;
    if (a == b) return ipv4.addr >= self.ipv4.addr;
    return false;
}

pub fn parse(cidr: []const u8) !Self {
    var it = std.mem.splitAny(u8, cidr, "/");
    const addr = it.next();
    const mask = it.next();
    if (addr == null) return error.InvalidCIDRv4;
    if (mask == null) return error.InvalidCIDRv4;
    if (it.next() != null) return error.InvalidCIDRv4;
    const a = try IPv4.parse(addr.?);
    const b = try std.fmt.parseInt(u32, mask.?, 0);
    if (b > 32) return error.InvalidCIDRv4;
    var m: u32 = std.math.maxInt(u32);
    m = std.math.shl(u32, m, 32 - b);
    return .{ .ipv4 = a, .mask = m };
}

pub fn bits(self: Self) u6 {
    return @popCount(self.mask);
}
