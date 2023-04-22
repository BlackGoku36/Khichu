const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const exe = b.addExecutable(.{
    .name = "example",
    });
    exe.addCSourceFile("src/main.c", &[_][]const u8 {});
    exe.addCSourceFile("src/parser.c", &[_][]const u8 {});
    exe.addCSourceFile("src/tokenizer.c", &[_][]const u8 {});
    exe.addCSourceFile("src/chunk.c", &[_][]const u8 {});
    exe.linkLibC();
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the compiler");
    run_step.dependOn(&run_cmd.step);
}
