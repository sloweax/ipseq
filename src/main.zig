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
    defer {
        switch (gpa.deinit()) {
            .ok => {},
            .leak => {
                std.io.getStdErr().writer().print("Memory leak detected\n", .{}) catch {};
            },
        }
    }

    var filter = root.Filter.init(gpa.allocator());
    defer filter.deinit();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help               shows usage and exits
        \\-f, --format <FMT>       output format (raw,hex,dot)
        \\-e, --exclude <SEQ>...   exclude sequence from output (this options can be used multiple times)
        \\-u, --unique             add sequence to exclude list after printing it
        \\-r, --exclude-reserved   exclude reserved cidrs
        \\<SEQ>...                 IPv4 | IPv6 | CIDRv4 | CIDRv6
        \\
    );

    const stdout = std.io.getStdOut();
    const stdoutw = stdout.writer().any();

    const parsers = comptime .{
        .FMT = clap.parsers.enumeration(Format),
        .SEQ = root.Sequence.parse,
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
            "::/128",
            "::1/128",
            "::ffff:0:0/96",
            "::ffff:0:0:0/96",
            "64:ff9b::/96",
            "64:ff9b:1::/48",
            "100::/64",
            "2001::/32",
            "2001:20::/28",
            "2001:db8::/32",
            "2002::/16",
            "3fff::/20",
            "5f00::/16",
            "fc00::/7",
            "fe80::/6",
            "ff00::/8",
        };

        for (reserved) |r| {
            try filter.addSequence(try root.Sequence.parse(r));
        }
    }

    if (res.args.format == null) res.args.format = .dot;

    for (res.args.exclude) |e| {
        try filter.addSequence(e);
    }

    var wbuf = std.io.bufferedWriter(stdoutw);
    const w = wbuf.writer().any();

    for (res.positionals) |seq| {
        if (filter.containsSequence(seq)) continue;

        switch (seq.v) {
            .ipv4 => |ip| {
                if (filter.containsIPv4(ip)) continue;
                try printIP(res.args.format.?, root.IPv4, ip, w);
            },
            .ipv6 => |ip| {
                if (filter.containsIPv6(ip)) continue;
                try printIP(res.args.format.?, root.IPv6, ip, w);
            },
            .cidrv4 => |v| {
                var it = v.iterator();
                while (it.next()) |ip| {
                    if (filter.containsIPv4(ip)) continue;
                    try printIP(res.args.format.?, root.IPv4, ip, w);
                }
            },
            .cidrv6 => |v| {
                var it = v.iterator();
                while (it.next()) |ip| {
                    if (filter.containsIPv6(ip)) continue;
                    try printIP(res.args.format.?, root.IPv6, ip, w);
                }
            },
        }

        if (res.args.unique != 0) try filter.addSequence(seq);
    }

    try wbuf.flush();
}

fn printIP(f: Format, comptime iptype: type, ip: anytype, writer: anytype) !void {
    switch (iptype) {
        root.IPv4 => {
            switch (f) {
                .dot => {
                    try writer.print("{}\n", .{ip});
                },
                .hex => {
                    try writer.print("{x}\n", .{ip.addr});
                },
                .raw => {
                    try writer.writeInt(u32, ip.addr, .big);
                },
            }
        },
        root.IPv6 => {
            switch (f) {
                .dot => {
                    try writer.print("{}\n", .{ip});
                },
                .hex => {
                    try writer.print("{x}\n", .{ip.addr});
                },
                .raw => {
                    try writer.writeInt(u128, ip.addr, .big);
                },
            }
        },
        else => unreachable,
    }
}

test {
    _ = @import("cidrv4_test.zig");
    _ = @import("ipv6.zig");
    _ = @import("cidrv6_test.zig");
    _ = @import("sequence.zig");
}
