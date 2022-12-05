const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const bench_implementation = b.option(enum { zig, c }, "impl", "Which impl of the benchmark to run") orelse .zig;
    const strip = b.option(bool, "strip", "Strip executable") orelse (mode != .Debug);

    const bench_impl_leo = b.addObject("benchmark-impl", "src/benchmark.zig");
    bench_impl_leo.setBuildMode(mode);
    bench_impl_leo.setTarget(target);
    bench_impl_leo.strip = strip;

    const bench_leo = b.addExecutable(switch (bench_implementation) {
        inline else => |tag| "benchmark-" ++ @tagName(tag),
    }, "rpmalloc-benchmark/benchmark/main.c");
    bench_leo.setBuildMode(mode);
    bench_leo.setTarget(target);

    bench_leo.addIncludePath("rpmalloc-benchmark/benchmark");
    bench_leo.addIncludePath("rpmalloc-benchmark/test");
    bench_leo.linkLibC();
    bench_leo.addCSourceFiles(&.{
        "rpmalloc-benchmark/test/thread.c",
        "rpmalloc-benchmark/test/timer.c",
    }, &.{ "-O3" });

    switch (bench_implementation) {
        .zig => bench_leo.addObject(bench_impl_leo),
        .c => bench_leo.addCSourceFiles(&.{
            "rpmalloc-benchmark/benchmark/rpmalloc/benchmark.c",
            "rpmalloc-benchmark/benchmark/rpmalloc/rpmalloc.c",
        }, &.{ "-O3" }),
    }
    bench_leo.install();

    const bench_run = bench_leo.run();
    bench_run.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        bench_run.addArgs(args);
    }
    bench_run.expected_exit_code = null;

    const bench_run_step = b.step("bench", "Run the benchmark");
    bench_run_step.dependOn(&bench_run.step);
}
