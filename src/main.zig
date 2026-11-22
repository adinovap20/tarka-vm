//! This module is the entry point for the tarka vm's core engine

const std = @import("std");
const VM = @import("tvm.zig").VM;

/// This function is the entry point of the tarka vm's core engine
pub fn main(init: std.process.Init) !void {
    var args = init.minimal.args.iterateAllocator(init.gpa) catch |err| {
        std.log.err("could not iterate over the provided command line arguments to tvm", .{});
        return err;
    };
    _ = args.next();

    const input_file = args.next() orelse {
        std.log.err("no binary file was provided to be interpreted", .{});
        return error.MissingInput;
    };

    const cwd = std.Io.Dir.cwd();
    const source = cwd.readFileAlloc(init.io, input_file, init.gpa, std.Io.Limit.limited(10 * 1024 * 1024)) catch |err| {
        std.log.err("could not read the binary file {s}", .{input_file});
        return err;
    };
    defer init.gpa.free(source);

    var vm = VM.init(source, init.gpa);
    defer vm.deinit();
    vm.execute() catch |err| {
        std.log.err("runtime error while executing", .{});
        return err;
    };
}
