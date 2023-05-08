const std = @import("std");
const Ast = @import("ast.zig").Ast;
const ByteCodePool = @import("bytecode.zig").ByteCodePool;
const ByteCode = @import("bytecode.zig").ByteCode;

fn generateCodeFromAst(ast: *Ast, node: u32, source: []u8, pool: *ByteCodePool) void {
    if (ast.nodes.items[node].left != std.math.nan_u32) {
        generateCodeFromAst(ast, ast.nodes.items[node].left, source, pool);
    }

    if (ast.nodes.items[node].right != std.math.nan_u32) {
        generateCodeFromAst(ast, ast.nodes.items[node].right, source, pool);
    }

    switch (ast.nodes.items[node].type) {
        .add => pool.emitBytecode(.bc_add),
        .sub => pool.emitBytecode(.bc_sub),
        .mult => pool.emitBytecode(.bc_mult),
        .div => pool.emitBytecode(.bc_div),
        .int_literal => {
            var int: i32 = 0;
            if (std.fmt.parseInt(i32, source[ast.nodes.items[node].loc.start..ast.nodes.items[node].loc.end], 10)) |out| {
                int = out;
            } else |err| {
                std.debug.print("Error while parsing int literal: {any}\n", .{err});
            }
            pool.emitBytecode(.bc_constant);
            pool.emitBytecode(@intToEnum(ByteCode, pool.addConstant(.{ .int = int })));
        },
        .float_literal => {
            var float: f32 = 0.0;
            if (std.fmt.parseFloat(f32, source[ast.nodes.items[node].loc.start..ast.nodes.items[node].loc.end])) |out| {
                float = out;
            } else |err| {
                std.debug.print("Error while parsing float literal: {any}\n", .{err});
            }
            pool.emitBytecode(.bc_constant);
            pool.emitBytecode(@intToEnum(ByteCode, pool.addConstant(.{ .float = float })));
        },
        .bool_literal => {
            var boolean: bool = false;
            if (source[ast.nodes.items[node].loc.start] == 't') {
                boolean = true;
            } else {
                boolean = false;
            }
            pool.emitBytecode(.bc_constant);
            pool.emitBytecode(@intToEnum(ByteCode, pool.addConstant(.{ .boolean = boolean })));
        },
        .bool_not => pool.emitBytecode(.bc_not),
        .bool_and => pool.emitBytecode(.bc_and),
        .bool_or => pool.emitBytecode(.bc_or),
        .negate => pool.emitBytecode(.bc_negate),
        .greater => pool.emitBytecode(.bc_greater),
        .lesser => pool.emitBytecode(.bc_less),
        .greater_equal => pool.emitBytecode(.bc_greater_than),
        .lesser_equal => pool.emitBytecode(.bc_less_than),
        .equal_equal => pool.emitBytecode(.bc_equal),
        .not_equal => pool.emitBytecode(.bc_not_equal),
    }
}

pub fn generateCode(ast: *Ast, node: u32, source: []u8, pool: *ByteCodePool) void {
    generateCodeFromAst(ast, node, source, pool);
    pool.emitBytecode(.bc_return);
}
