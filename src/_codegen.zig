const std = @import("std");
const Ast = @import("ast.zig").Ast;
const ByteCodePool = @import("bytecode.zig").ByteCodePool;
const ByteCode = @import("bytecode.zig").ByteCode;
const Value = @import("bytecode.zig").Value;
const SymbolTable = @import("tables.zig").SymbolTable;

fn generateCodeFromAst(ast: *Ast, node_idx: u32, source: []u8, pool: *ByteCodePool) void {
    if (ast.nodes.items[node_idx].left != std.math.nan_u32) {
        generateCodeFromAst(ast, ast.nodes.items[node_idx].left, source, pool);
    }

    if (ast.nodes.items[node_idx].right != std.math.nan_u32) {
        generateCodeFromAst(ast, ast.nodes.items[node_idx].right, source, pool);
    }

    switch (ast.nodes.items[node_idx].type) {
        .add => pool.emitBytecodeOp(.op_add),
        .sub => pool.emitBytecodeOp(.op_sub),
        .mult => pool.emitBytecodeOp(.op_mult),
        .div => pool.emitBytecodeOp(.op_div),
        .int_literal => {
            var int: i32 = 0;
            if (std.fmt.parseInt(i32, source[ast.nodes.items[node_idx].loc.start..ast.nodes.items[node_idx].loc.end], 10)) |out| {
                int = out;
            } else |err| {
                std.debug.print("Error while parsing int literal: {any}\n", .{err});
            }
            pool.emitBytecodeAdd(.op_constant, pool.addConstant(.{ .int = int }));
        },
        .float_literal => {
            var float: f32 = 0.0;
            if (std.fmt.parseFloat(f32, source[ast.nodes.items[node_idx].loc.start..ast.nodes.items[node_idx].loc.end])) |out| {
                float = out;
            } else |err| {
                std.debug.print("Error while parsing float literal: {any}\n", .{err});
            }
            pool.emitBytecodeAdd(.op_constant, pool.addConstant(.{ .float = float }));
        },
        .bool_literal => {
            var boolean: bool = false;
            if (source[ast.nodes.items[node_idx].loc.start] == 't') {
                boolean = true;
            } else {
                boolean = false;
            }
            pool.emitBytecodeAdd(.op_constant, pool.addConstant(.{ .boolean = boolean }));
        },
        .bool_not => pool.emitBytecodeOp(.op_not),
        .bool_and => pool.emitBytecodeOp(.op_and),
        .bool_or => pool.emitBytecodeOp(.op_or),
        .negate => pool.emitBytecodeOp(.op_negate),
        .greater => pool.emitBytecodeOp(.op_greater),
        .lesser => pool.emitBytecodeOp(.op_less),
        .greater_equal => pool.emitBytecodeOp(.op_greater_than),
        .lesser_equal => pool.emitBytecodeOp(.op_less_than),
        .equal_equal => pool.emitBytecodeOp(.op_equal),
        .not_equal => pool.emitBytecodeOp(.op_not_equal),
        .identifier => {
            const name: []u8 = source[ast.nodes.items[node_idx].loc.start..ast.nodes.items[node_idx].loc.end];
            // TODO: Add check for identifier not declared
            pool.emitBytecodeAdd(.op_unload_gv, @intCast(pool.global_var_tables.values.getIndex(name).?));
        },
        .assign_stmt => {
            const left = ast.nodes.items[node_idx].left;
            const right = ast.nodes.items[node_idx].right;
            generateCodeFromAst(ast, right, source, pool);
            const name: []u8 = source[ast.nodes.items[left].loc.start..ast.nodes.items[left].loc.end];
            // TODO: Add check for identifier not declared
            pool.emitBytecodeAdd(.op_load_gv, @intCast(pool.global_var_tables.values.getIndex(name).?));
        },
        else => {},
    }
}

pub fn generateCode(ast: *Ast, node_idx: u32, source: []u8, pool: *ByteCodePool) void {
    // generateCodeFromAst(ast, node, source, pool);
    // pool.emitBytecodeOp(.op_return);

    switch (ast.nodes.items[node_idx].type) {
        .var_stmt => {
            const node = ast.nodes.items[node_idx];
            const symbol_entry = SymbolTable.varTable.get(node.symbol_idx);
            generateCodeFromAst(ast, symbol_entry.expr_node, source, pool);
            var value: Value = undefined;
            switch (symbol_entry.type) {
                .t_int => {
                    value = .{ .int = 0 };
                },
                .t_float => {
                    value = .{ .float = 0.0 };
                },
                .t_bool => {
                    value = .{ .boolean = false };
                },
            }
            pool.global_var_tables.values.put(symbol_entry.name, value) catch |err| {
                std.debug.print("Unable to create global variable entry: {}", .{err});
            };
            pool.emitBytecodeAdd(.op_load_gv, @intCast(pool.global_var_tables.values.getIndex(symbol_entry.name).?));
        },
        .print_stmt => {
            const left = ast.nodes.items[node_idx].left;
            generateCodeFromAst(ast, left, source, pool);
            pool.emitBytecodeOp(.op_print);
        },
        .assign_stmt => {
            const left = ast.nodes.items[node_idx].left;
            const right = ast.nodes.items[node_idx].right;
            generateCodeFromAst(ast, right, source, pool);
            const name: []u8 = source[ast.nodes.items[left].loc.start..ast.nodes.items[left].loc.end];
            // TODO: Add check for identifier not declared
            pool.emitBytecodeAdd(.op_load_gv, @intCast(pool.global_var_tables.values.getIndex(name).?));
        },
        else => {},
    }
    // pool.emitBytecodeOp(.op_return);
}
