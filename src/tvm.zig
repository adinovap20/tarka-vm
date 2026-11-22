//! This module handles the virtual machine logic

const std = @import("std");
const testing = std.testing;

/// This struct holds the entire logic of the tarka virtual machine
pub const VM = struct {
    /// allocator to allocate memory for stack
    allocator: std.mem.Allocator,

    /// fat pointer pointing to the original bytes read from the file
    source: []const u8,

    /// instruction pointer
    ip: usize = 0,

    /// current byte
    cur: u8 = 0,

    /// stack of u64 elements
    stack: std.ArrayList(u64) = .empty,

    /// This function initializes the VM struct
    pub fn init(source: []const u8, allocator: std.mem.Allocator) VM {
        return VM{ .source = source, .allocator = allocator };
    }

    /// This function frees any allcoated memory by the VM instance
    pub fn deinit(self: *VM) void {
        self.stack.deinit(self.allocator);
    }

    /// This function interprets the bytecode at runtime
    pub fn execute(self: *VM) !void {
        while (self.ip < self.source.len) {
            self.cur = self.source[self.ip];
            switch (self.cur) {
                0x00 => self.execute_halt(),
                0x01 => try self.execute_push(),
                else => {
                    return error.InstParseError;
                },
            }
        }
    }

    /// executes halt instruction
    fn execute_halt(_: *VM) void {
        std.process.exit(0);
    }

    /// executes push instruction
    fn execute_push(self: *VM) !void {
        if (self.ip + 8 >= self.source.len) {
            return error.PushInstParseError;
        }
        const value = std.mem.readInt(u64, self.source[self.ip + 1 ..][0..8], .little);
        self.stack.append(self.allocator, value) catch |err| {
            return err;
        };
        self.ip += 9;
    }
};

test "push fails if half instruction is provided" {
    var vm = VM.init(&[_]u8{ 0x01, 0x00, 0x00, 0x00 }, testing.allocator);
    defer vm.deinit();

    try testing.expectError(error.PushInstParseError, vm.execute_push());
}

test "push is successful" {
    var vm = VM.init(&[_]u8{ 0x01, 0x0A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }, testing.allocator);
    defer vm.deinit();

    try vm.execute_push();
    try testing.expectEqual(vm.stack.items.len, 1);
    try testing.expectEqual(vm.stack.getLast(), @as(u64, 10));
    try testing.expectEqual(vm.ip, 9);
}
