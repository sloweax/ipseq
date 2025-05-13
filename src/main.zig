const std = @import("std");
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

    while (args.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "-")) {
            const opt = blk: {
                if (std.mem.startsWith(u8, arg, "--")) {
                    break :blk arg[2..];
                }
                break :blk arg[1..];
            };

            const usage =
                \\usage: {s} [-h] [-e cidr] [-r] [cidr...]
                \\
                \\options:
                \\    -h, --help              shows usage and exits
                \\    -e, --exclude           exclude cidr from output (this options can be
                \\                            used multiple times)
                \\    -r, --exclude-reserved  exclude reserved cidrs
                \\
            ;

            if (std.mem.eql(u8, opt, "h") or std.mem.eql(u8, opt, "help")) {
                try stdoutw.print(usage, .{progname});
                std.process.exit(0);
            } else if (std.mem.eql(u8, opt, "e") or std.mem.eql(u8, opt, "exclude")) {
                const val = args.next();
                if (val == null) {
                    try stderrw.print("-e requires an argument\n", .{});
                    std.process.exit(1);
                }
                try excludes.append(try CIDRv4.parse(val.?));
            } else if (std.mem.eql(u8, opt, "r") or std.mem.eql(u8, opt, "exclude-reserved")) {
                try excludes.appendSlice(&[_]CIDRv4{
                    try CIDRv4.parse("0.0.0.0/8"),
                    try CIDRv4.parse("10.0.0.0/8"),
                    try CIDRv4.parse("100.64.0.0/10"),
                    try CIDRv4.parse("127.0.0.0/8"),
                    try CIDRv4.parse("169.254.0.0/16"),
                    try CIDRv4.parse("172.16.0.0/12"),
                    try CIDRv4.parse("192.0.0.0/24"),
                    try CIDRv4.parse("192.0.2.0/24"),
                    try CIDRv4.parse("192.88.99.0/24"),
                    try CIDRv4.parse("192.168.0.0/16"),
                    try CIDRv4.parse("198.18.0.0/15"),
                    try CIDRv4.parse("198.51.100.0/24"),
                    try CIDRv4.parse("203.0.113.0/24"),
                    try CIDRv4.parse("224.0.0.0/4"),
                    try CIDRv4.parse("233.252.0.0/24"),
                    try CIDRv4.parse("240.0.0.0/4"),
                    try CIDRv4.parse("255.255.255.255/32"),
                });
            } else {
                try stderrw.print("unknown option {s}\n", .{arg});
            }
        } else {
            try includes.append(try CIDRv4.parse(arg));
        }
    }

    for (includes.items) |i| {
        var it = i.iterator();
        outer: while (it.next()) |ip| {
            for (excludes.items) |e| {
                if (e.contains(ip)) continue :outer;
            }
            const buf = std.mem.asBytes(&ip);
            try w.print("{}.{}.{}.{}\n", .{ buf[3], buf[2], buf[1], buf[0] });
        }
    }

    try wbuf.flush();
}

test {
    _ = @import("cidrv4_test.zig");
}
