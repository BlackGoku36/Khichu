const std = @import("std");

pub const opCode = enum{
    op_return,
    op_constant,
    op_negate,
    op_add,
    op_sub,
    op_mult,
    op_div,
    op_greater,
    op_less,
    op_greater_than,
    op_less_than,
    op_equal,
    op_not_equal,
    op_not,
    op_and,
    op_or,
    op_load_gv,
    op_unload_gv,
    op_print,
};

pub const ByteCode = struct{
    op_code: opCode,
    address: u32,
};

pub const ValueType = enum { int, float, boolean };
pub const Value = union(ValueType) {
    int: i32,
    float: f32,
    boolean: bool,
};

pub const GlobalVarTables = struct{
    values: std.StringArrayHashMap(Value),

    pub fn init(allocator: std.mem.Allocator) GlobalVarTables {
        return .{
            .values = std.StringArrayHashMap(Value).init(allocator),
        };
    }

    pub fn print(gv_table: *GlobalVarTables) void {
        var map_iter = gv_table.values.iterator();
        while(map_iter.next()) |entry|{
            std.debug.print("key: {s}, ", .{entry.key_ptr.*});
            switch (entry.value_ptr.*) {
                .int => |val| std.debug.print("value: {d}\n", .{val}),
                .float => |val| std.debug.print("value: {d}\n", .{val}),
                .boolean => |val| std.debug.print("value: {any}\n", .{val}),
            }
        }
    }

    pub fn deinit(gv_table: *GlobalVarTables) void {
        gv_table.values.deinit();
    }
};

pub const ByteCodePool = struct {
    bytecodes: std.ArrayList(ByteCode),
    global_var_tables: GlobalVarTables,
    values: std.ArrayList(Value),

    pub fn init(allocator: std.mem.Allocator) ByteCodePool {
        return .{
            .bytecodes = std.ArrayList(ByteCode).init(allocator),
            .global_var_tables = GlobalVarTables.init(allocator),
            .values = std.ArrayList(Value).init(allocator),
        };
    }

    pub fn deinit(pool: *ByteCodePool) void {
        pool.bytecodes.deinit();
        pool.values.deinit();
        pool.global_var_tables.deinit();
    }

    pub fn emitBytecodeOp(pool: *ByteCodePool, op_code: opCode) void {
        pool.bytecodes.append(.{.op_code = op_code, .address = std.math.nan_u32}) catch |err| {
            std.debug.print("Error while adding to bytecodes: {any}\n", .{err});
        };
    }

    pub fn emitBytecodeAdd(pool: *ByteCodePool, op_code: opCode, address: u32) void {
        pool.bytecodes.append(.{.op_code = op_code, .address = address}) catch |err| {
            std.debug.print("Error while adding to bytecodes: {any}\n", .{err});
        };
    }

    pub fn addConstant(pool: *ByteCodePool, value: Value) u32 {
        pool.values.append(value) catch |err| {
            std.debug.print("Error while adding to values: {any}\n", .{err});
        };
        return @intCast(pool.values.items.len - 1);
    }

    pub fn print(pool: *ByteCodePool) void {
        var offset: u32 = 0;

        while (offset < pool.bytecodes.items.len) {
            switch (pool.bytecodes.items[offset].op_code) {
                .op_return => {
                    std.debug.print("op_return\n", .{});
                    offset += 1;
                },
                .op_constant => {
                    std.debug.print("op_constant: ", .{});
                    var value = pool.values.items[pool.bytecodes.items[offset].address];
                    switch (value) {
                        .int => |val| std.debug.print("{d}\n", .{val}),
                        .float => |val| std.debug.print("{d}\n", .{val}),
                        .boolean => |val| std.debug.print("{any}\n", .{val}),
                    }
                    offset += 1;
                },
                .op_negate => {
                    std.debug.print("op_negate\n", .{});
                    offset += 1;
                },
                .op_add => {
                    std.debug.print("op_add\n", .{});
                    offset += 1;
                },
                .op_sub => {
                    std.debug.print("op_sub\n", .{});
                    offset += 1;
                },
                .op_mult => {
                    std.debug.print("op_mult\n", .{});
                    offset += 1;
                },
                .op_div => {
                    std.debug.print("op_div\n", .{});
                    offset += 1;
                },
                .op_greater => {
                    std.debug.print("op_greater\n", .{});
                    offset += 1;
                },
                .op_less => {
                    std.debug.print("op_less\n", .{});
                    offset += 1;
                },
                .op_greater_than => {
                    std.debug.print("op_greater_than\n", .{});
                    offset += 1;
                },
                .op_less_than => {
                    std.debug.print("op_less_than\n", .{});
                    offset += 1;
                },
                .op_equal => {
                    std.debug.print("op_equal\n", .{});
                    offset += 1;
                },
                .op_not_equal => {
                    std.debug.print("op_not_equal\n", .{});
                    offset += 1;
                },
                .op_not => {
                    std.debug.print("op_not\n", .{});
                    offset += 1;
                },
                .op_and => {
                    std.debug.print("op_and\n", .{});
                    offset += 1;
                },
                .op_or => {
                    std.debug.print("op_or\n", .{});
                    offset += 1;
                },
                .op_load_gv => {
                    std.debug.print("op_load_gv: {d}\n", .{pool.bytecodes.items[offset].address});
                    offset += 1;
                },
                .op_unload_gv => {
                    std.debug.print("op_unload_gv: {d}\n", .{pool.bytecodes.items[offset].address});
                    offset += 1;
                },
                .op_print => {
                    std.debug.print("op_print\n", .{});
                    offset += 1;
                }
            }
        }
    }
};
