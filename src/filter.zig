const std = @import("std");
const root = @import("root.zig");
const Self = @This();

a: std.mem.Allocator,
cidrv4s: std.ArrayList(root.IPv4.CIDR),
cidrv6s: std.ArrayList(root.IPv6.CIDR),

pub fn init(a: std.mem.Allocator) Self {
    return .{
        .a = a,
        .cidrv4s = std.ArrayList(root.IPv4.CIDR).init(a),
        .cidrv6s = std.ArrayList(root.IPv6.CIDR).init(a),
    };
}

pub fn deinit(self: *Self) void {
    self.cidrv4s.deinit();
    self.cidrv6s.deinit();
}

pub fn addSequence(self: *Self, seq: root.Sequence) !void {
    switch (seq.v) {
        .cidrv4 => |v| {
            try self.addCIDRv4(v);
        },
        .cidrv6 => |v| {
            try self.addCIDRv6(v);
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

pub fn containsCIDRv4(self: *Self, cidr: root.IPv4.CIDR) bool {
    for (self.cidrv4s.items) |c| {
        if (c.contains(cidr.min()) and c.contains(cidr.max()))
            return true;
    }
    return false;
}

pub fn containsCIDRv6(self: *Self, cidr: root.IPv6.CIDR) bool {
    for (self.cidrv6s.items) |c| {
        if (c.contains(cidr.min()) and c.contains(cidr.max()))
            return true;
    }
    return false;
}

pub fn containsIPv4(self: *Self, ip: root.IPv4) bool {
    for (self.cidrv4s.items) |c| {
        if (c.contains(ip)) return true;
    }
    return false;
}

pub fn containsIPv6(self: *Self, ip: root.IPv6) bool {
    for (self.cidrv6s.items) |c| {
        if (c.contains(ip)) return true;
    }
    return false;
}
