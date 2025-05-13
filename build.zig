const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const link_libc = b.option(bool, "lc", "Wheather to link libc");
    const linkage = b.option(std.builtin.LinkMode, "linkage", "Linkage mode");
    const subsystem = b.option(std.Target.SubSystem, "subsystem", "Subsystem");
    const strip = b.option(bool, "strip", "Wheather to strip binary");

    const exe = b.addExecutable(.{
        .name = "ipseq",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .strip = strip,
        .link_libc = link_libc,
        .optimize = optimize,
        .linkage = linkage,
    });
    exe.subsystem = subsystem;

    const test_step = b.step("test", "Run unit tests");
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    var run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);

    b.installArtifact(exe);
}
