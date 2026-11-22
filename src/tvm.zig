//! This module handles the virtual machine logic

const std = @import("std");

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

    pub fn execute(self: *VM) !void {
        while (self.ip < self.source.len) {
            self.cur = self.source[self.ip];
            switch (self.cur) {
                0x00 => self.execute_halt(),
                else => {
                    std.log.err("unknown byte found at position {d} in the byte stream", .{self.ip});
                    return error.UnknownByte;
                },
            }
        }
    }

    fn execute_halt(_: *VM) void {
        std.process.exit(0);
    }
};
