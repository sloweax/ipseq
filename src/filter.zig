const std = @import("std");
const root = @import("root.zig");
const Self = @This();

a: std.mem.Allocator,
cidrv4s: std.ArrayList(root.IPv4.CIDR),
cidrv6s: std.ArrayList(root.IPv6.CIDR),
ipv4s: std.AutoHashMap(root.IPv4, void),
ipv6s: std.AutoHashMap(root.IPv6, void),

pub fn init(a: std.mem.Allocator) Self {
    return .{
        .a = a,
        .cidrv4s = std.ArrayList(root.IPv4.CIDR).init(a),
        .cidrv6s = std.ArrayList(root.IPv6.CIDR).init(a),
        .ipv4s = std.AutoHashMap(root.IPv4, void).init(a),
        .ipv6s = std.AutoHashMap(root.IPv6, void).init(a),
    };
}

pub fn deinit(self: *Self) void {
    self.cidrv4s.deinit();
    self.cidrv6s.deinit();
    self.ipv4s.deinit();
    self.ipv6s.deinit();
}

pub fn addSequence(self: *Self, seq: root.Sequence) !void {
    switch (seq.v) {
        .cidrv4 => |v| {
            try self.addCIDRv4(v);
        },
        .cidrv6 => |v| {
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
    }
}

pub fn addCIDRv4(self: *Self, cidr: root.IPv4.CIDR) !void {
    if (cidr.bits() == 32) {
        try self.ipv4s.put(cidr.min(), void{});
        return;
    }
    if (!self.containsCIDRv4(cidr))
        try self.cidrv4s.append(cidr);
}

pub fn addCIDRv6(self: *Self, cidr: root.IPv6.CIDR) !void {
    if (cidr.bits() == 128) {
        try self.ipv6s.put(cidr.min(), void{});
        return;
    }
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
    if (self.ipv4s.get(ip) != null) return true;
    for (self.cidrv4s.items) |c| {
        if (c.contains(ip)) return true;
    }
    return false;
}

pub fn containsIPv6(self: *Self, ip: root.IPv6) bool {
    if (self.ipv6s.get(ip) != null) return true;
    for (self.cidrv6s.items) |c| {
        if (c.contains(ip)) return true;
    }
    return false;
}
