const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "common",
        .root_source_file = b.path("src/common.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    const common_module = b.addModule("common", .{
        .root_source_file = b.path("src/common.zig"),
    });
    lib.root_module.addImport("common", common_module);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/common.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    //TODO make sure this works, add doc comments to everything
    const install_docs = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    const docs_step = b.step("docs", "Generate documentation");
    docs_step.dependOn(&install_docs.step);
}
