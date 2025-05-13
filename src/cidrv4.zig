const std = @import("std");

ipv4: u32,
mask: u32,
bits: u6,

const Self = @This();

const Iterator = struct {
    cidr: Self,
    end: u32,
    cur: u32 = 0,
    eof: bool = false,

    pub fn next(self: *@This()) ?u32 {
        if (self.eof) return null;
        var tmp = self.cidr.ipv4 & self.cidr.mask;
        tmp |= self.cur;
        if (self.cur >= self.end) {
            self.eof = true;
        } else {
            self.cur += 1;
        }
        return tmp;
    }
};

pub fn min(self: Self) u32 {
    return self.ipv4;
}

pub fn max(self: Self) u32 {
    const end: u32 = @intCast(std.math.pow(u33, 2, 32 - self.bits) - 1);
    return self.ipv4 | end;
}

pub fn contains(self: Self, ipv4: u32) bool {
    const a = self.ipv4 & self.mask;
    const b = ipv4 & self.mask;
    if (a == b) return ipv4 >= self.ipv4;
    return false;
}

pub fn parse(cidr: []const u8) !Self {
    var it = std.mem.splitAny(u8, cidr, "/");
    const addr = it.next();
    const mask = it.next();
    if (addr == null) return error.InvalidCIDRv4;
    if (mask == null) return error.InvalidCIDRv4;
    const a = try parseIPv4(addr.?);
    const b = try std.fmt.parseInt(u32, mask.?, 0);
    if (b > 32) return error.InvalidCIDRv4;
    var m: u32 = std.math.maxInt(u32);
    m = std.math.shl(u32, m, 32 - b);
    return .{ .ipv4 = a, .mask = m, .bits = @intCast(b) };
}

pub fn iterator(self: Self) Iterator {
    return .{
        .cidr = self,
        .end = @intCast(std.math.pow(u33, 2, 32 - self.bits) - 1),
        .cur = self.ipv4 & (~self.mask),
    };
}

pub fn parseIPv4(ip: []const u8) !u32 {
    var r: u32 = 0;
    var count: usize = 0;
    var it = std.mem.splitAny(u8, ip, ".");

    while (it.next()) |entry| {
        count += 1;
        if (count > 4) return error.InvalidIPv4;
        const tmp = std.fmt.parseInt(u8, entry, 0) catch {
            return error.InvalidIPv4;
        };
        r *= 256;
        r += tmp;
    }

    if (count != 4) return error.InvalidIPv4;

    return r;
}
