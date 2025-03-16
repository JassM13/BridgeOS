const std = @import("std");
const CrossTarget = std.zig.CrossTarget;
const Target = std.Target;
const Step = std.Build.Step;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Configure target for x86 freestanding environment
    const targetQuery = .{
        .cpu_arch = Target.Cpu.Arch.x86,
        .os_tag = Target.Os.Tag.freestanding,
        .abi = .none,
        .ofmt = .elf,
        .cpu_model = .{ .explicit = &std.Target.x86.cpu.i386 },
    };

    const target = b.resolveTargetQuery(targetQuery);

    // Use ReleaseFast optimization for better performance
    const optimize = .ReleaseFast;

    // Create the executable for stage2
    const exe = b.addExecutable(.{
        .name = "stage2",
        .root_source_file = b.path("stage2/main.zig"),
        .target = target,
        .optimize = optimize,
        .linkage = .static,
    });

    // Set the linker script
    exe.setLinkerScriptPath(b.path("linker.ld"));

    // Add build options
    const options = b.addOptions();
    const kernel_size = b.option(usize, "kernel_size", "size of kernel") orelse 30;
    options.addOption(usize, "kernel_size", kernel_size);
    exe.root_module.addOptions("build_options", options);

    // Define NASM source files
    const nasm_sources = [_][]const u8{
        "stage2/entry.asm",
        "stage2/interrupt.asm",
        "boot_sector/boot.asm",
    };

    // Install the executable artifact
    b.installArtifact(exe);

    // Compile NASM sources and add them to the executable
    const nasm_out = compileNasmSource(b, &nasm_sources);
    for (nasm_out) |out| {
        exe.addObjectFile(.{ .cwd_relative = out });
    }

    // Create binary output
    const bin = exe.addObjCopy(.{
        .basename = "bootloader.bin",
        .format = .bin,
    });

    // Install the binary file
    const install_step = b.addInstallBinFile(bin.getOutput(), bin.basename);
    b.getInstallStep().dependOn(&install_step.step);
}

// Helper function to replace file extension
fn replaceExtension(b: *std.Build, path: []const u8, new_extension: []const u8) []const u8 {
    const basename = std.fs.path.basename(path);
    const ext = std.fs.path.extension(basename);
    return b.fmt("{s}{s}", .{ basename[0 .. basename.len - ext.len], new_extension });
}

// Function to compile NASM source files
fn compileNasmSource(b: *std.Build, comptime nasm_sources: []const []const u8) [nasm_sources.len][]const u8 {
    const compile_step = b.step("nasm", "compile nasm source");

    // Create output directory
    const mkdir = b.addSystemCommand(&.{ "mkdir", "-p", "zig-out/bin" });
    compile_step.dependOn(&mkdir.step);

    var outputSources: [nasm_sources.len][]const u8 = undefined;
    for (nasm_sources, 0..) |src, idx| {
        const out = b.fmt("zig-out/bin/{s}", .{replaceExtension(b, src, ".o")});
        const create_bin = b.addSystemCommand(&.{ "nasm", "-f", "elf32", src, "-o", out });
        create_bin.step.dependOn(&mkdir.step);
        outputSources[idx] = out;

        compile_step.dependOn(&create_bin.step);
    }

    b.getInstallStep().dependOn(compile_step);
    return outputSources;
}
