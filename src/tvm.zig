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
                0x02 => try self.execute_pop(),
                0x03 => try self.execute_dup(),
                0x04 => try self.execute_swap(),
                0x10 => try self.execute_print_i64(),
                0x20 => try self.execute_add(),
                0x21 => try self.execute_sub(),
                0x22 => try self.execute_mul(),
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
        try self.stack.append(self.allocator, value);
        self.ip += 9;
    }

    /// executes pop instruction
    fn execute_pop(self: *VM) !void {
        _ = self.stack.pop() orelse return error.StackUnderflow;
        self.ip += 1;
    }

    /// executes dup instruction
    fn execute_dup(self: *VM) !void {
        try self.stack.append(self.allocator, self.stack.last() orelse return error.StackUnderflow);
        self.ip += 1;
    }

    /// executes swap instruction
    fn execute_swap(self: *VM) !void {
        if (self.stack.items.len < 2) return error.StackUnderflow;
        const tmp = self.stack.items[self.stack.items.len - 1];
        self.stack.items[self.stack.items.len - 1] = self.stack.items[self.stack.items.len - 2];
        self.stack.items[self.stack.items.len - 2] = tmp;
        self.ip += 1;
    }

    /// executes print.i64 instruction
    fn execute_print_i64(self: *VM) !void {
        std.debug.print("{d}\n", .{@as(i64, @intCast(self.stack.last() orelse return error.StackUnderflow))});
        self.ip += 1;
    }

    /// executes add instruction
    fn execute_add(self: *VM) !void {
        const val1 = self.stack.pop() orelse return error.StackUnderflow;
        const val2 = self.stack.pop() orelse return error.StackUnderflow;
        const result = val1 + val2;
        if (result <= std.math.minInt(i64) or result >= std.math.maxInt(i64)) return error.IntegerOverflow;
        try self.stack.append(self.allocator, result);
        self.ip += 1;
    }

    /// executes sub instruction
    fn execute_sub(self: *VM) !void {
        const val1 = self.stack.pop() orelse return error.StackUnderflow;
        const val2 = self.stack.pop() orelse return error.StackUnderflow;
        const result = val2 - val1;
        if (result <= std.math.minInt(i64) or result >= std.math.maxInt(i64)) return error.IntegerOverflow;
        try self.stack.append(self.allocator, result);
        self.ip += 1;
    }

    /// executes mul instruction
    fn execute_mul(self: *VM) !void {
        const val1 = self.stack.pop() orelse return error.StackUnderflow;
        const val2 = self.stack.pop() orelse return error.StackUnderflow;
        const result = val2 * val1;
        if (result <= std.math.minInt(i64) or result >= std.math.maxInt(i64)) return error.IntegerOverflow;
        try self.stack.append(self.allocator, result);
        self.ip += 1;
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

test "pop fails in case of underflow" {
    var vm = VM.init(&[_]u8{}, testing.allocator);
    defer vm.deinit();

    try testing.expectError(error.StackUnderflow, vm.execute_pop());
}

test "pop is successful" {
    var vm = VM.init(&[_]u8{0x02}, testing.allocator);
    defer vm.deinit();
    try vm.stack.append(testing.allocator, @as(u64, 20));

    try vm.execute_pop();
    try testing.expectEqual(vm.stack.items.len, 0);
    try testing.expectEqual(vm.ip, 1);
}

test "dup fails in case of underflow" {
    var vm = VM.init(&[_]u8{}, testing.allocator);
    defer vm.deinit();

    try testing.expectError(error.StackUnderflow, vm.execute_dup());
}

test "dup is successful" {
    var vm = VM.init(&[_]u8{0x03}, testing.allocator);
    defer vm.deinit();
    try vm.stack.append(testing.allocator, @as(u64, 10));

    try vm.execute_dup();
    try testing.expectEqual(vm.stack.items.len, 2);
    try testing.expectEqualSlices(u64, vm.stack.items, &[2]u64{ 10, 10 });
    try testing.expectEqual(vm.ip, 1);
}

test "swap fails in case of underflow" {
    var vm = VM.init(&[_]u8{}, testing.allocator);
    defer vm.deinit();
    try testing.expectError(error.StackUnderflow, vm.execute_swap());
    try vm.stack.append(vm.allocator, @as(u64, 10));
    try testing.expectError(error.StackUnderflow, vm.execute_swap());
}

test "swap is successful" {
    var vm = VM.init(&[_]u8{}, testing.allocator);
    defer vm.deinit();
    try vm.stack.append(vm.allocator, @as(u64, 10));
    try vm.stack.append(vm.allocator, @as(u64, 20));

    try vm.execute_swap();
    try testing.expectEqual(vm.stack.items.len, 2);
    try testing.expectEqualSlices(u64, vm.stack.items, &[2]u64{ 20, 10 });
    try testing.expectEqual(vm.ip, 1);
}
