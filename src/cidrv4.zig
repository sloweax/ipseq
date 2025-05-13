const std = @import("std");

ipv4: u32,
mask: u32,

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
    if (self.bits() == 0) return std.math.maxInt(u32);
    return self.ipv4 | (std.math.pow(u32, 2, 32 - self.bits()) - 1);
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
    return .{ .ipv4 = a, .mask = m };
}

pub fn iterator(self: Self) Iterator {
    return .{
        .cidr = self,
        .end = self.max() & (~self.mask),
        .cur = self.ipv4 & (~self.mask),
    };
}

pub fn bits(self: Self) u6 {
    return @popCount(self.mask);
}

pub fn parseIPv4(ip: []const u8) !u32 {
    if (std.mem.containsAtLeast(u8, ip, 1, ".")) {
        var count: usize = 0;
        var it = std.mem.splitAny(u8, ip, ".");
        var r: u32 = 0;
        while (it.next()) |entry| {
            count += 1;
            if (count > 4) return error.InvalidIPv4;
            const tmp = std.fmt.parseInt(u8, entry, 0) catch {
                return error.InvalidIPv4;
            };
            r *= 256;
            r += tmp;
        }
        return r;
    }

    return std.fmt.parseInt(u32, ip, 0) catch {
        return error.InvalidIPv4;
    };
}
