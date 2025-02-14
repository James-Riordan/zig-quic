const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ✅ Define the main library module
    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ✅ Expose `src/` as a module for clean imports
    const zig_quic_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
    });

    lib_mod.addImport("zig_quic", zig_quic_mod);

    // ✅ Build the static library
    const lib = b.addStaticLibrary(.{
        .name = "zig-quic",
        .root_module = lib_mod,
    });

    b.installArtifact(lib);
    lib.linkLibC(); // ✅ Link libc for networking

    // ✅ Define a test step for each test file
    const test_sources = [_][]const u8{
        "src/root.zig",
        "src/http3.zig",
        "src/quic.zig",
        "src/transport/congestion.zig",
        "src/transport/connection.zig",
        "src/transport/packet.zig",
        "src/transport/stream.zig",
    };

    const test_step = b.step("test", "Run all unit tests");

    for (test_sources) |file| {
        const test_unit = b.addTest(.{ .root_source_file = b.path(file) });
        const run_test_unit = b.addRunArtifact(test_unit);
        test_step.dependOn(&run_test_unit.step);
    }

    // ✅ Integration Tests (Runs tests in `src/tests/integration/`)
    const integration_tests = b.addTest(.{
        .root_source_file = b.path("src/tests/integration/integration_tests.zig"),
    });

    integration_tests.root_module.addImport("zig_quic", zig_quic_mod);

    const run_integration_tests = b.addRunArtifact(integration_tests);
    const integration_step = b.step("integration-test", "Run integration tests");
    integration_step.dependOn(&run_integration_tests.step);
}
