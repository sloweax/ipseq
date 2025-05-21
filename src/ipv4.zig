const std = @import("std");
const builtin = @import("builtin");
const Self = @This();
const native_endian = builtin.cpu.arch.endian();
pub const CIDR = @import("cidrv4.zig");
pub const Range = @import("rangev4.zig");

addr: u32,

pub fn parse(ip: []const u8) !Self {
    if (std.mem.containsAtLeast(u8, ip, 1, ".")) {
        var count: usize = 0;
        var it = std.mem.splitScalar(u8, ip, '.');
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

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    const buf = std.mem.asBytes(&self.addr);
    switch (native_endian) {
        .big => {
            try writer.print("{}.{}.{}.{}", .{ buf[0], buf[1], buf[2], buf[3] });
        },
        .little => {
            try writer.print("{}.{}.{}.{}", .{ buf[3], buf[2], buf[1], buf[0] });
        },
    }
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
