const clap = @import("clap");
const std = @import("std");
const builtin = @import("builtin");
const root = @import("root.zig");

pub fn main() void {
    run() catch |err| switch (err) {
        error.BrokenPipe => {
            return;
        },
        else => {
            std.process.exit(1);
        },
    };
}

const Format = enum { dot, hex, raw };

fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var excludes = std.ArrayList(root.IPv4.CIDR).init(gpa.allocator());
    defer excludes.deinit();

    var includes = std.ArrayList(root.IPv4.CIDR).init(gpa.allocator());
    defer includes.deinit();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help               shows usage and exits
        \\-f, --format <FMT>       output format (raw,hex,dot)
        \\-e, --exclude <CIDR>...  exclude cidr from output (this options can be used multiple times)
        \\-u, --unique             add cidr to exclude list after printing it
        \\-r, --exclude-reserved   exclude reserved cidrs
        \\<CIDR>...
        \\
    );

    const stdout = std.io.getStdOut();
    const stdoutw = stdout.writer().any();

    const parsers = comptime .{
        .FMT = clap.parsers.enumeration(Format),
        .CIDR = root.IPv4.CIDR.parse,
    };

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, parsers, .{
        .diagnostic = &diag,
        .allocator = gpa.allocator(),
    }) catch |err| {
        try diag.report(std.io.getStdErr().writer(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        var it = std.process.ArgIterator.init();
        const progname = blk: {
            if (it.next()) |name| {
                break :blk name;
            }
            break :blk "(null)";
        };
        try stdoutw.print("usage: {s} ", .{progname});
        try clap.usage(stdoutw, clap.Help, &params);
        try stdoutw.print("\n\noptions:\n", .{});
        try clap.help(stdoutw, clap.Help, &params, .{});
        return;
    }

    if (res.args.@"exclude-reserved" > 0) {
        const reserved = [_][]const u8{
            "0.0.0.0/8",
            "10.0.0.0/8",
            "100.64.0.0/10",
            "127.0.0.0/8",
            "169.254.0.0/16",
            "172.16.0.0/12",
            "192.0.0.0/24",
            "192.0.2.0/24",
            "192.88.99.0/24",
            "192.168.0.0/16",
            "198.18.0.0/15",
            "198.51.100.0/24",
            "203.0.113.0/24",
            "224.0.0.0/4",
            "233.252.0.0/24",
            "240.0.0.0/4",
            "255.255.255.255/32",
        };

        for (reserved) |r| {
            try appendCIDRv4(&excludes, try root.IPv4.CIDR.parse(r));
        }
    }

    if (res.args.format == null) res.args.format = .dot;

    for (res.args.exclude) |e| {
        try appendCIDRv4(&excludes, e);
    }

    for (res.positionals) |i| {
        try appendCIDRv4(&includes, i);
    }

    var wbuf = std.io.bufferedWriter(stdoutw);
    var w = wbuf.writer().any();

    nextcidr: for (includes.items) |i| {
        for (excludes.items) |e| {
            if (e.contains(i.min()) and e.contains(i.max())) continue :nextcidr;
        }

        var it = i.iterator();
        nextip: while (it.next()) |ip| {
            for (excludes.items) |e| {
                if (e.contains(ip)) continue :nextip;
            }
            switch (res.args.format.?) {
                .dot => {
                    try w.print("{}\n", .{ip});
                },
                .hex => {
                    try w.print("{x}\n", .{ip.addr});
                },
                .raw => {
                    try w.writeInt(u32, ip.addr, .big);
                },
            }
        }

        if (res.args.unique != 0) try appendCIDRv4(&excludes, i);
    }

    try wbuf.flush();
}

fn appendCIDRv4(a: *std.ArrayList(root.IPv4.CIDR), cidr: root.IPv4.CIDR) !void {
    for (a.items) |c| {
        if (c.contains(cidr.min()) and c.contains(cidr.max())) return;
    }
    try a.append(cidr);
}

test {
    _ = @import("cidrv4_test.zig");
}
