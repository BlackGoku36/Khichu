const std = @import("std");

const ByteCodePool = @import("bytecode.zig").ByteCodePool;
const ByteCode = @import("bytecode.zig").ByteCode;
const ValueType = @import("bytecode.zig").ValueType;
const Value = @import("bytecode.zig").Value;

pub const VM = struct {
    pool: ByteCodePool,
    stack: std.ArrayList(Value),
    ip: u32 = 0,

    pub fn init(allocator: std.mem.Allocator, pool: ByteCodePool) VM {
        return .{
            .pool = pool,
            .stack = std.ArrayList(Value).init(allocator),
        };
    }

    pub fn deinit(vm: *VM) void {
        vm.stack.deinit();
    }

    fn readInstruction(vm: *VM) ByteCode {
        const bc = vm.pool.bytecodes.items[vm.ip];
        vm.ip += 1;
        return bc;
    }

    pub fn run(vm: *VM) !void {
        while (vm.ip < vm.pool.bytecodes.items.len) {
            const instruction = vm.readInstruction();
            switch (instruction) {
                .bc_return => {
                    const value = vm.stack.pop();
                    switch (value) {
                        .int => |val| std.debug.print("{d}\n", .{val}),
                        .float => |val| std.debug.print("{d}\n", .{val}),
                        .boolean => |val| std.debug.print("{any}\n", .{val}),
                    }
                    return;
                },
                .bc_constant => {
                    try vm.stack.append(vm.pool.values.items[@intFromEnum(vm.readInstruction())]);
                },
                .bc_not => {
                    var value = vm.stack.pop();
                    switch (value) {
                        .int => std.debug.print("Invalid type for bc_not operation\n", .{}),
                        .float => std.debug.print("Invalid type for bc_not operation\n", .{}),
                        .boolean => value.boolean = !value.boolean,
                    }
                    try vm.stack.append(value);
                },
                .bc_negate => {
                    var value = vm.stack.pop();
                    switch (value) {
                        .int => value.int = -value.int,
                        .float => value.float = -value.float,
                        .boolean => std.debug.print("Invalid type for bc_negate operation\n", .{}),
                    }
                    try vm.stack.append(value);
                },
                .bc_add => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    switch (a) {
                        .int => a.int += b.int,
                        .float => a.float += b.float,
                        .boolean => std.debug.print("Invalid type for bc_add operation\n", .{}),
                    }
                    try vm.stack.append(a);
                },
                .bc_sub => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    switch (a) {
                        .int => a.int -= b.int,
                        .float => a.float -= b.float,
                        .boolean => std.debug.print("Invalid type for bc_sub operation\n", .{}),
                    }
                    try vm.stack.append(a);
                },
                .bc_mult => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    switch (a) {
                        .int => a.int *= b.int,
                        .float => a.float *= b.float,
                        .boolean => std.debug.print("Invalid type for bc_mult operation\n", .{}),
                    }
                    try vm.stack.append(a);
                },
                .bc_div => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    switch (a) {
                        .int => a.int = @divExact(a.int, b.int),
                        .float => a.float /= b.float,
                        .boolean => std.debug.print("Invalid type for bc_div operation\n", .{}),
                    }
                    try vm.stack.append(a);
                },
                .bc_greater => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    var c: Value = .{ .boolean = false };
                    switch (a) {
                        .int => c.boolean = a.int > b.int,
                        .float => c.boolean = a.float > b.float,
                        .boolean => std.debug.print("Invalid type for bc_greater operation\n", .{}),
                    }
                    try vm.stack.append(c);
                },
                .bc_less => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    var c: Value = .{ .boolean = false };
                    switch (a) {
                        .int => c.boolean = a.int < b.int,
                        .float => c.boolean = a.float < b.float,
                        .boolean => std.debug.print("Invalid type for bc_less operation\n", .{}),
                    }
                    try vm.stack.append(c);
                },
                .bc_greater_than => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    var c: Value = .{ .boolean = false };
                    switch (a) {
                        .int => c.boolean = a.int >= b.int,
                        .float => c.boolean = a.float >= b.float,
                        .boolean => std.debug.print("Invalid type for bc_greater_than operation\n", .{}),
                    }
                    try vm.stack.append(c);
                },
                .bc_less_than => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    var c: Value = .{ .boolean = false };
                    switch (a) {
                        .int => c.boolean = a.int <= b.int,
                        .float => c.boolean = a.float <= b.float,
                        .boolean => std.debug.print("Invalid type for bc_less_than operation\n", .{}),
                    }
                    try vm.stack.append(c);
                },
                .bc_equal => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    var c: Value = .{ .boolean = false };
                    switch (a) {
                        .int => c.boolean = a.int == b.int,
                        .float => c.boolean = a.float == b.float,
                        .boolean => c.boolean = a.boolean == b.boolean,
                    }
                    try vm.stack.append(c);
                },
                .bc_not_equal => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    var c: Value = .{ .boolean = false };
                    switch (a) {
                        .int => c.boolean = a.int != b.int,
                        .float => c.boolean = a.float != b.float,
                        .boolean => c.boolean = a.boolean != b.boolean,
                    }
                    try vm.stack.append(c);
                },
                .bc_and => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    switch (a) {
                        .int => std.debug.print("Invalid type for bc_and operation\n", .{}),
                        .float => std.debug.print("Invalid type for bc_and operation\n", .{}),
                        .boolean => a.boolean = a.boolean and b.boolean,
                    }
                    try vm.stack.append(a);
                },
                .bc_or => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    switch (a) {
                        .int => std.debug.print("Invalid type for bc_or operation\n", .{}),
                        .float => std.debug.print("Invalid type for bc_or operation\n", .{}),
                        .boolean => a.boolean = a.boolean or b.boolean,
                    }
                    try vm.stack.append(a);
                },
            }
        }
    }
};
