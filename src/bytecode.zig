const std = @import("std");

pub const ByteCode = enum {
    bc_return,
    bc_constant,
    bc_negate,
    bc_add,
    bc_sub,
    bc_mult,
    bc_div,
    bc_greater,
    bc_less,
    bc_greater_than,
    bc_less_than,
    bc_equal,
    bc_not_equal,
    bc_not,
    bc_and,
    bc_or,

    // pub fn str(bytecode: *ByteCode) []u8 {
    //     switch(bytecode){
    //         bc_return => "bc_return",
    //         bc_constant => "bc_constant",
    //         bc_negate => "bc_negate",
    //         bc_add => "bc_add",
    //         bc_sub => "bc_sub",
    //         bc_mult => "bc_mult",
    //         bc_div => "bc_div",
    //         bc_true => "bc_true",
    //         bc_false => "bc_false",
    //         bc_greater => "bc_greater",
    //         bc_less => "bc_less",
    //         bc_greater_than => "bc_greater_than",
    //         bc_less_than => "bc_less_than",
    //         bc_equal => "bc_equal",
    //         bc_not_equal => "bc_not_equal",
    //         bc_not => "bc_not",
    //         bc_and => "bc_and",
    //         bc_or => "bc_or",
    //     }
    // }
};

pub const ValueType = enum { int, float, boolean };
pub const Value = union(ValueType) {
    int: i32,
    float: f32,
    boolean: bool,
};

pub const ByteCodePool = struct {
    bytecodes: std.ArrayList(ByteCode),
    values: std.ArrayList(Value),

    pub fn init(allocator: std.mem.Allocator) ByteCodePool {
        return .{
            .bytecodes = std.ArrayList(ByteCode).init(allocator),
            .values = std.ArrayList(Value).init(allocator),
        };
    }

    pub fn deinit(pool: *ByteCodePool) void {
        pool.bytecodes.deinit();
        pool.values.deinit();
    }

    pub fn emitBytecode(pool: *ByteCodePool, bytecode: ByteCode) void {
        pool.bytecodes.append(bytecode) catch |err| {
            std.debug.print("Error while adding to bytecodes: {any}\n", .{err});
        };
    }

    pub fn addConstant(pool: *ByteCodePool, value: Value) u32 {
        pool.values.append(value) catch |err| {
            std.debug.print("Error while adding to values: {any}\n", .{err});
        };
        return @intCast(u32, pool.values.items.len - 1);
    }

    pub fn print(pool: *ByteCodePool) void {
        var offset: u32 = 0;

        while (offset < pool.bytecodes.items.len) {
            switch (pool.bytecodes.items[offset]) {
                .bc_return => {
                    std.debug.print("bc_return\n", .{});
                    offset += 1;
                },
                .bc_constant => {
                    std.debug.print("bc_constant: ", .{});
                    var value = pool.values.items[@enumToInt(pool.bytecodes.items[offset + 1])];
                    switch (value) {
                        .int => |val| std.debug.print("{d}\n", .{val}),
                        .float => |val| std.debug.print("{d}\n", .{val}),
                        .boolean => |val| std.debug.print("{any}\n", .{val}),
                    }
                    offset += 2;
                },
                .bc_negate => {
                    std.debug.print("bc_negate\n", .{});
                    offset += 1;
                },
                .bc_add => {
                    std.debug.print("bc_add\n", .{});
                    offset += 1;
                },
                .bc_sub => {
                    std.debug.print("bc_sub\n", .{});
                    offset += 1;
                },
                .bc_mult => {
                    std.debug.print("bc_mult\n", .{});
                    offset += 1;
                },
                .bc_div => {
                    std.debug.print("bc_div\n", .{});
                    offset += 1;
                },
                .bc_greater => {
                    std.debug.print("bc_greater\n", .{});
                    offset += 1;
                },
                .bc_less => {
                    std.debug.print("bc_less\n", .{});
                    offset += 1;
                },
                .bc_greater_than => {
                    std.debug.print("bc_greater_than\n", .{});
                    offset += 1;
                },
                .bc_less_than => {
                    std.debug.print("bc_less_than\n", .{});
                    offset += 1;
                },
                .bc_equal => {
                    std.debug.print("bc_equal\n", .{});
                    offset += 1;
                },
                .bc_not_equal => {
                    std.debug.print("bc_not_equal\n", .{});
                    offset += 1;
                },
                .bc_not => {
                    std.debug.print("bc_not\n", .{});
                    offset += 1;
                },
                .bc_and => {
                    std.debug.print("bc_and\n", .{});
                    offset += 1;
                },
                .bc_or => {
                    std.debug.print("bc_or\n", .{});
                    offset += 1;
                },
            }
        }
    }
};
