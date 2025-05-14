const std = @import("std");
const Self = @This();
pub const CIDR = @import("cidrv4.zig");

addr: u32,

pub fn parse(ip: []const u8) !Self {
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
        return .{ .addr = r };
    }

    return .{ .addr = std.fmt.parseInt(u32, ip, 0) catch {
        return error.InvalidIPv4;
    } };
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
