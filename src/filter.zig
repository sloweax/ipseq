const std = @import("std");
const root = @import("root.zig");
const Self = @This();

a: std.mem.Allocator,
cidrv4s: std.ArrayList(root.IPv4.CIDR),
cidrv6s: std.ArrayList(root.IPv6.CIDR),
rangev4s: std.ArrayList(root.IPv4.Range),
rangev6s: std.ArrayList(root.IPv6.Range),
ipv4s: std.AutoHashMap(root.IPv4, void),
ipv6s: std.AutoHashMap(root.IPv6, void),
seq_expansion: ?u129,

pub fn init(a: std.mem.Allocator, x: ?u129) Self {
    return .{
        .a = a,
        .rangev4s = std.ArrayList(root.IPv4.Range).init(a),
        .rangev6s = std.ArrayList(root.IPv6.Range).init(a),
        .cidrv4s = std.ArrayList(root.IPv4.CIDR).init(a),
        .cidrv6s = std.ArrayList(root.IPv6.CIDR).init(a),
        .ipv4s = std.AutoHashMap(root.IPv4, void).init(a),
        .ipv6s = std.AutoHashMap(root.IPv6, void).init(a),
        .seq_expansion = x,
    };
}

pub fn deinit(self: *Self) void {
    self.cidrv4s.deinit();
    self.cidrv6s.deinit();
    self.ipv4s.deinit();
    self.ipv6s.deinit();
    self.rangev4s.deinit();
    self.rangev6s.deinit();
}

pub fn addSequence(self: *Self, seq: root.Sequence) !void {
    switch (seq.v) {
        .rangev4 => |v| {
            if (self.seq_expansion) |sz| {
                if (sz >= seq.len()) {
                    for (@as(u9, v.start[0])..@as(u9, v.end[0]) + 1) |n1| for (@as(u9, v.start[1])..@as(u9, v.end[1]) + 1) |n2| for (@as(u9, v.start[2])..@as(u9, v.end[2]) + 1) |n3| for (@as(u9, v.start[3])..@as(u9, v.end[3]) + 1) |n4| {
                        const addr = n4 + (n3 << 8) + (n2 << 16) + (n1 << 24);
                        try self.ipv4s.put(.{ .addr = @intCast(addr) }, void{});
                    };
                    return;
                }
            }
            try self.addRangev4(v);
        },
        .rangev6 => |v| {
            if (self.seq_expansion) |sz| {
                if (sz >= seq.len()) {
                    for (@as(u17, v.start[0])..@as(u17, v.end[0]) + 1) |n1| for (@as(u17, v.start[1])..@as(u17, v.end[1]) + 1) |n2| for (@as(u17, v.start[2])..@as(u17, v.end[2]) + 1) |n3| for (@as(u17, v.start[3])..@as(u17, v.end[3]) + 1) |n4| for (@as(u17, v.start[4])..@as(u17, v.end[4]) + 1) |n5| for (@as(u17, v.start[5])..@as(u17, v.end[5]) + 1) |n6| for (@as(u17, v.start[6])..@as(u17, v.end[6]) + 1) |n7| for (@as(u17, v.start[7])..@as(u17, v.end[7]) + 1) |n8| {
                        const nums: [8]u16 = .{ @intCast(n1), @intCast(n2), @intCast(n3), @intCast(n4), @intCast(n5), @intCast(n6), @intCast(n7), @intCast(n8) };
                        var addr: u128 = 0;
                        inline for (nums) |n| {
                            addr *= 65536;
                            addr += n;
                        }
                        try self.ipv6s.put(.{ .addr = @intCast(addr) }, void{});
                    };
                    return;
                }
            }
            try self.addRangev6(v);
        },
        .cidrv4 => |v| {
            if (self.seq_expansion) |sz| {
                if (sz >= seq.len()) {
                    var ip = v.min().addr;
                    const max = v.max().addr;
                    while (true) : (ip += 1) {
                        try self.ipv4s.put(.{ .addr = ip }, void{});
                        if (ip == max) break;
                    }
                    return;
                }
            }
            try self.addCIDRv4(v);
        },
        .cidrv6 => |v| {
            if (self.seq_expansion) |sz| {
                if (sz >= seq.len()) {
                    var ip = v.min().addr;
                    const max = v.max().addr;
                    while (true) : (ip += 1) {
                        try self.ipv6s.put(.{ .addr = ip }, void{});
                        if (ip == max) break;
                    }
                    return;
                }
            }
            try self.addCIDRv6(v);
        },
        .ipv4 => |v| {
            try self.ipv4s.put(v, void{});
        },
        .ipv6 => |v| {
            try self.ipv6s.put(v, void{});
        },
    }
}

pub fn containsSequence(self: *Self, seq: root.Sequence) bool {
    switch (seq.v) {
        .cidrv4 => |v| {
            return self.containsCIDRv4(v);
        },
        .cidrv6 => |v| {
            return self.containsCIDRv6(v);
        },
        .ipv4 => |v| {
            return self.containsIPv4(v);
        },
        .ipv6 => |v| {
            return self.containsIPv6(v);
        },
        .rangev4 => |v| {
            return self.containsRangev4(v);
        },
        .rangev6 => |v| {
            return self.containsRangev6(v);
        },
    }
}

pub fn addCIDRv4(self: *Self, cidr: root.IPv4.CIDR) !void {
    if (!self.containsCIDRv4(cidr))
        try self.cidrv4s.append(cidr);
}

pub fn addCIDRv6(self: *Self, cidr: root.IPv6.CIDR) !void {
    if (!self.containsCIDRv6(cidr))
        try self.cidrv6s.append(cidr);
}

pub fn addRangev4(self: *Self, range: root.IPv4.Range) !void {
    if (!self.containsRangev4(range))
        try self.rangev4s.append(range);
}

pub fn addRangev6(self: *Self, range: root.IPv6.Range) !void {
    if (!self.containsRangev6(range))
        try self.rangev6s.append(range);
}

pub fn containsRangev4(self: *Self, range: root.IPv4.Range) bool {
    for (self.cidrv4s.items) |c| {
        if (c.contains(range.min()) and c.contains(range.max()))
            return true;
    }
    for (self.rangev4s.items) |r| {
        if (r.contains(range.min()) and r.contains(range.max()))
            return true;
    }
    if (range.len() == 1) return self.ipv4s.contains(range.min());
    return false;
}

pub fn containsRangev6(self: *Self, range: root.IPv6.Range) bool {
    for (self.cidrv6s.items) |c| {
        if (c.contains(range.min()) and c.contains(range.max()))
            return true;
    }
    for (self.rangev6s.items) |r| {
        if (r.contains(range.min()) and r.contains(range.max()))
            return true;
    }
    if (range.len() == 1) return self.ipv6s.contains(range.min());
    return false;
}

pub fn containsCIDRv4(self: *Self, cidr: root.IPv4.CIDR) bool {
    for (self.cidrv4s.items) |c| {
        if (c.contains(cidr.min()) and c.contains(cidr.max()))
            return true;
    }
    for (self.rangev4s.items) |r| {
        if (r.contains(cidr.min()) and r.contains(cidr.max()))
            return true;
    }
    if (cidr.len() == 1) return self.ipv4s.contains(cidr.min());
    return false;
}

pub fn containsCIDRv6(self: *Self, cidr: root.IPv6.CIDR) bool {
    for (self.cidrv6s.items) |c| {
        if (c.contains(cidr.min()) and c.contains(cidr.max()))
            return true;
    }
    for (self.rangev6s.items) |r| {
        if (r.contains(cidr.min()) and r.contains(cidr.max()))
            return true;
    }
    if (cidr.len() == 1) return self.ipv6s.contains(cidr.min());
    return false;
}

pub fn containsIPv4(self: *Self, ip: root.IPv4) bool {
    if (self.ipv4s.contains(ip)) return true;
    for (self.cidrv4s.items) |c| {
        if (c.contains(ip)) return true;
    }
    for (self.rangev4s.items) |r| {
        if (r.contains(ip)) return true;
    }
    return false;
}

pub fn containsIPv6(self: *Self, ip: root.IPv6) bool {
    if (self.ipv6s.contains(ip)) return true;
    for (self.cidrv6s.items) |c| {
        if (c.contains(ip)) return true;
    }
    for (self.rangev6s.items) |r| {
        if (r.contains(ip)) return true;
    }
    return false;
}
