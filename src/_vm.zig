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
            switch (instruction.op_code) {
                .op_return => {
                    // const value = vm.stack.pop();
                    // switch (value) {
                    // .int => |val| std.debug.print("{d}\n", .{val}),
                    // .float => |val| std.debug.print("{d}\n", .{val}),
                    // .boolean => |val| std.debug.print("{any}\n", .{val}),
                    // }
                    return;
                },
                .op_constant => {
                    try vm.stack.append(vm.pool.values.items[instruction.address]);
                },
                .op_not => {
                    var value = vm.stack.pop();
                    switch (value) {
                        .int => std.debug.print("Invalid type for op_not operation\n", .{}),
                        .float => std.debug.print("Invalid type for op_not operation\n", .{}),
                        .boolean => value.boolean = !value.boolean,
                    }
                    try vm.stack.append(value);
                },
                .op_negate => {
                    var value = vm.stack.pop();
                    switch (value) {
                        .int => value.int = -value.int,
                        .float => value.float = -value.float,
                        .boolean => std.debug.print("Invalid type for op_negate operation\n", .{}),
                    }
                    try vm.stack.append(value);
                },
                .op_add => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    switch (a) {
                        .int => a.int += b.int,
                        .float => a.float += b.float,
                        .boolean => std.debug.print("Invalid type for op_add operation\n", .{}),
                    }
                    try vm.stack.append(a);
                },
                .op_sub => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    switch (a) {
                        .int => a.int -= b.int,
                        .float => a.float -= b.float,
                        .boolean => std.debug.print("Invalid type for op_sub operation\n", .{}),
                    }
                    try vm.stack.append(a);
                },
                .op_mult => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    switch (a) {
                        .int => a.int *= b.int,
                        .float => a.float *= b.float,
                        .boolean => std.debug.print("Invalid type for op_mult operation\n", .{}),
                    }
                    try vm.stack.append(a);
                },
                .op_div => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    switch (a) {
                        .int => a.int = @divExact(a.int, b.int),
                        .float => a.float /= b.float,
                        .boolean => std.debug.print("Invalid type for op_div operation\n", .{}),
                    }
                    try vm.stack.append(a);
                },
                .op_greater => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    var c: Value = .{ .boolean = false };
                    switch (a) {
                        .int => c.boolean = a.int > b.int,
                        .float => c.boolean = a.float > b.float,
                        .boolean => std.debug.print("Invalid type for op_greater operation\n", .{}),
                    }
                    try vm.stack.append(c);
                },
                .op_less => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    var c: Value = .{ .boolean = false };
                    switch (a) {
                        .int => c.boolean = a.int < b.int,
                        .float => c.boolean = a.float < b.float,
                        .boolean => std.debug.print("Invalid type for op_less operation\n", .{}),
                    }
                    try vm.stack.append(c);
                },
                .op_greater_than => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    var c: Value = .{ .boolean = false };
                    switch (a) {
                        .int => c.boolean = a.int >= b.int,
                        .float => c.boolean = a.float >= b.float,
                        .boolean => std.debug.print("Invalid type for op_greater_than operation\n", .{}),
                    }
                    try vm.stack.append(c);
                },
                .op_less_than => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    var c: Value = .{ .boolean = false };
                    switch (a) {
                        .int => c.boolean = a.int <= b.int,
                        .float => c.boolean = a.float <= b.float,
                        .boolean => std.debug.print("Invalid type for op_less_than operation\n", .{}),
                    }
                    try vm.stack.append(c);
                },
                .op_equal => {
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
                .op_not_equal => {
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
                .op_and => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    switch (a) {
                        .int => std.debug.print("Invalid type for op_and operation\n", .{}),
                        .float => std.debug.print("Invalid type for op_and operation\n", .{}),
                        .boolean => a.boolean = a.boolean and b.boolean,
                    }
                    try vm.stack.append(a);
                },
                .op_or => {
                    var b = vm.stack.pop();
                    var a = vm.stack.pop();
                    switch (a) {
                        .int => std.debug.print("Invalid type for op_or operation\n", .{}),
                        .float => std.debug.print("Invalid type for op_or operation\n", .{}),
                        .boolean => a.boolean = a.boolean or b.boolean,
                    }
                    try vm.stack.append(a);
                },
                .op_load_gv => {
                    var a = vm.stack.pop();
                    var key = vm.pool.global_var_tables.values.keys()[instruction.address];
                    vm.pool.global_var_tables.values.put(key, a) catch |err| {
                        std.debug.print("Unable to assign value to variable: {}", .{err});
                    };
                },
                .op_unload_gv => {
                    var value = vm.pool.global_var_tables.values.values()[instruction.address];
                    try vm.stack.append(value);
                },
                .op_print => {
                    const value = vm.stack.pop();
                    switch (value) {
                        .int => |val| std.debug.print("{d}\n", .{val}),
                        .float => |val| std.debug.print("{d}\n", .{val}),
                        .boolean => |val| std.debug.print("{any}\n", .{val}),
                    }
                },
            }
        }
    }
};
