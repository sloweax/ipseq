const std = @import("std");
const builtin = @import("builtin");
const native_endian = builtin.cpu.arch.endian();
const CIDRv4 = @import("cidrv4.zig");

pub fn main() void {
    run() catch |err| switch (err) {
        error.BrokenPipe => {
            return;
        },
        else => {
            std.debug.print("{}\n", .{err});
            std.process.exit(1);
        },
    };
}

const Format = enum { dot, hex, raw };
const Option = enum {
    h,
    help,
    f,
    format,
    u,
    unique,
    e,
    exclude,
    r,
    @"exclude-reserved",
};

fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var excludes = std.ArrayList(CIDRv4).init(gpa.allocator());
    defer excludes.deinit();

    var includes = std.ArrayList(CIDRv4).init(gpa.allocator());
    defer includes.deinit();

    var args = std.process.ArgIterator.init();
    defer args.deinit();

    const progname = blk: {
        const tmp = args.next();
        if (tmp) |a| {
            break :blk a;
        }
        break :blk "(null)";
    };

    const stdout = std.io.getStdOut();
    const stdoutw = stdout.writer().any();
    const stderr = std.io.getStdErr();
    const stderrw = stderr.writer().any();
    var wbuf = std.io.bufferedWriter(stdoutw);
    var w = wbuf.writer().any();

    var unique = false;
    var format = Format.dot;

    while (args.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "-")) {
            const optname = blk: {
                if (std.mem.startsWith(u8, arg, "--")) {
                    break :blk arg[2..];
                }
                break :blk arg[1..];
            };

            const opt: ?Option = std.meta.stringToEnum(Option, optname);
            if (opt == null) {
                try stderrw.print("unknown option {s}\n", .{arg});
                std.process.exit(1);
            }

            switch (opt.?) {
                .h, .help => {
                    const usage =
                        \\usage: {s} [-h] [-f fmt] [-e cidr] [-u] [-r] [cidr...]
                        \\
                        \\options:
                        \\    -h, --help              shows usage and exits
                        \\    -f, --format            output format (raw,hex,dot)
                        \\    -e, --exclude           exclude cidr from output (this options can be
                        \\                            used multiple times)
                        \\    -u, --unique            add cidr to exclude list after printing it
                        \\    -r, --exclude-reserved  exclude reserved cidrs
                        \\
                    ;
                    try stdoutw.print(usage, .{progname});
                    std.process.exit(0);
                },
                .f, .format => {
                    const val = args.next();
                    if (val == null) {
                        try stderrw.print("-f requires an argument\n", .{});
                        std.process.exit(1);
                    }
                    const tmp = std.meta.stringToEnum(Format, val.?);
                    if (tmp == null) {
                        try stderrw.print("-f {s} is invalid\n", .{val.?});
                        std.process.exit(1);
                    }
                    format = tmp.?;
                },
                .e, .exclude => {
                    const val = args.next();
                    if (val == null) {
                        try stderrw.print("-e requires an argument\n", .{});
                        std.process.exit(1);
                    }
                    try appendCIDRv4(&excludes, try CIDRv4.parse(val.?));
                },
                .u, .unique => {
                    unique = true;
                },
                .r, .@"exclude-reserved" => {
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
                        try appendCIDRv4(&excludes, try CIDRv4.parse(r));
                    }
                },
            }
        } else {
            try appendCIDRv4(&includes, try CIDRv4.parse(arg));
        }
    }

    nextcidr: for (includes.items) |i| {
        for (excludes.items) |e| {
            if (e.contains(i.min()) and e.contains(i.max())) continue :nextcidr;
        }

        var it = i.iterator();
        nextip: while (it.next()) |ip| {
            for (excludes.items) |e| {
                if (e.contains(ip)) continue :nextip;
            }
            switch (format) {
                .dot => {
                    const buf = std.mem.asBytes(&ip);
                    switch (native_endian) {
                        .little => {
                            try w.print("{}.{}.{}.{}\n", .{ buf[3], buf[2], buf[1], buf[0] });
                        },
                        .big => {
                            try w.print("{}.{}.{}.{}\n", .{ buf[0], buf[1], buf[2], buf[3] });
                        },
                    }
                },
                .hex => {
                    try w.print("{x}\n", .{ip});
                },
                .raw => {
                    try w.writeInt(u32, ip, .big);
                },
            }
        }

        if (unique) try appendCIDRv4(&excludes, i);
    }

    try wbuf.flush();
}

fn appendCIDRv4(a: *std.ArrayList(CIDRv4), cidr: CIDRv4) !void {
    for (a.items) |c| {
        if (c.contains(cidr.min()) and c.contains(cidr.max())) return;
    }
    try a.append(cidr);
}

test {
    _ = @import("cidrv4_test.zig");
}
