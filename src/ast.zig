const std = @import("std");
const LocInfo = @import("tokenizer.zig").LocInfo;
const tables = @import("tables.zig");
const SymbolTable = tables.SymbolTable;
const FnCallTable = tables.FnCallTable;
const IfTable = tables.IfTable;
const MultiScopeTable = tables.MultiScopeTable;
const FnTable = tables.FnTable;

const nan_u32 = 0x7FC00000;
const nan_u64 = 0x7FF8000000000000;

pub const Type = enum {
    ast_int_literal,
    ast_float_literal,
    ast_bool_literal,
    ast_bool_not,
    ast_bool_and,
    ast_bool_or,
    ast_greater,
    ast_lesser,
    ast_greater_equal,
    ast_lesser_equal,
    ast_equal_equal,
    ast_not_equal,
    ast_negate,
    ast_mult,
    ast_div,
    ast_add,
    ast_sub,
    ast_identifier,
    ast_var_stmt,
    ast_print_stmt,
    ast_assign_stmt,
    ast_fn_block,
    ast_fn_call,
    ast_fn_return,
    ast_if,
    ast_while,

    pub fn strType(ast_type: Type) []const u8 {
        switch (ast_type) {
            .ast_int_literal => return "int",
            .ast_float_literal => return "float",
            .ast_bool_literal => return "bool",
            else => {
                unreachable;
            },
        }
    }

    pub fn str(ast_type: Type) []const u8 {
        switch (ast_type) {
            .ast_int_literal => return "int_literal",
            .ast_float_literal => return "float_literal",
            .ast_bool_literal => return "bool_literal",
            .ast_bool_not => return "bool_not",
            .ast_bool_and => return "bool_and",
            .ast_bool_or => return "bool_or",
            .ast_greater => return "greater",
            .ast_lesser => return "lesser",
            .ast_greater_equal => return "greater_equal",
            .ast_lesser_equal => return "lesser_equal",
            .ast_equal_equal => return "equal_equal",
            .ast_not_equal => return "not_equal",
            .ast_negate => return "negate",
            .ast_mult => return "mult",
            .ast_div => return "div",
            .ast_add => return "add",
            .ast_sub => return "sub",
            .ast_identifier => return "identifier",
            .ast_var_stmt => return "var_stmt",
            .ast_print_stmt => return "print_stmt",
            .ast_assign_stmt => return "assign_stmt",
            .ast_fn_block => return "fn_block",
            .ast_fn_call => return "fn_call",
            .ast_fn_return => return "fn_return",
            .ast_if => return "if",
            .ast_while => return "while",
        }
    }
};

pub const Node = struct {
    loc: LocInfo,
    type: Type,
    idx: usize,
    left: u32,
    right: u32,

    pub fn isTypeLiteral(node: Node) bool {
        return node.type == .ast_int_literal or node.type == .ast_float_literal or node.type == .ast_bool_literal;
    }

    pub fn isNumberalLiteral(node: Node) bool {
        return node.type == .ast_int_literal or node.type == .ast_float_literal;
    }

    pub fn isComparisonOp(node: Node) bool {
        return node.type == .ast_greater or node.type == .ast_lesser or node.type == .ast_greater_equal or node.type == .ast_lesser_equal or node.type == .ast_equal_equal or node.type == .ast_not_equal;
    }
};

pub const Ast = struct {
    nodes: std.ArrayList(Node),

    pub fn init(allocator: std.mem.Allocator) Ast {
        return .{
            .nodes = std.ArrayList(Node).init(allocator),
        };
    }

    pub fn deinit(ast: *Ast) void {
        ast.nodes.deinit();
    }

    pub fn setNodeIdx(ast: *Ast, atIndex: usize, index: usize) void {
        ast.nodes.items[atIndex].idx = index;
    }

    pub fn addNode(ast: *Ast, node_type: Type, idx: usize, left: u32, right: u32, loc: LocInfo) u32 {
        const node_idx: u32 = @as(u32, @intCast(ast.nodes.items.len));
        ast.nodes.append(.{ .type = node_type, .idx = idx, .left = left, .right = right, .loc = loc }) catch |err| {
            std.debug.print("Error while adding node: {any}", .{err});
        };
        return node_idx;
    }

    pub fn addUnaryNode(ast: *Ast, node_type: Type, idx: usize, left: u32, loc: LocInfo) u32 {
        return ast.addNode(node_type, idx, left, nan_u32, loc);
    }

    pub fn addLiteralNode(ast: *Ast, node_type: Type, idx: usize, loc: LocInfo) u32 {
        return ast.addNode(node_type, idx, nan_u32, nan_u32, loc);
    }

    pub fn print(ast: *Ast, node: usize, left: u8, level: u32) void {
        if (ast.nodes.items[node].right != nan_u32) {
            ast.print(ast.nodes.items[node].right, 2, level + 1);
        }

        indent(level);
        if (left == 1) {
            std.debug.print("{s} (left) (self_idx: {d}) (out_idx: {d})\n", .{ ast.nodes.items[node].type.str(), node, ast.nodes.items[node].idx });
        } else if (left == 2) {
            std.debug.print("{s} (right) (self_idx: {d}) (out_idx: {d})\n", .{ ast.nodes.items[node].type.str(), node, ast.nodes.items[node].idx });
        } else {
            std.debug.print("{s} (root) (self_idx: {d}) (out_idx: {d})\n", .{ ast.nodes.items[node].type.str(), node, ast.nodes.items[node].idx });
        }

        if (ast.nodes.items[node].left != nan_u32) {
            ast.print(ast.nodes.items[node].left, 1, level + 1);
        }
    }

    pub fn indent(level: u32) void {
        for (0..level) |i| {
            _ = i;
            std.debug.print("{s}", .{"  "});
        }
    }

    pub fn print_block(ast: *Ast, root_idx: usize, left: u8, level: u32) void {
        const ast_node = ast.nodes.items[root_idx];
        switch (ast_node.type) {
            .ast_var_stmt => {
                const symbol_idx = ast_node.idx;
                const symbol_entry = SymbolTable.varTable.get(symbol_idx);
                ast.print(symbol_entry.expr_node, left, level);
            },
            .ast_print_stmt => {
                const left_idx = ast_node.left;
                ast.print(left_idx, left, level);
            },
            .ast_assign_stmt => {
                const right_idx = ast_node.right;
                ast.print(right_idx, left, level);
            },
            .ast_fn_return => {
                const left_idx = ast_node.left;
                ast.print(left_idx, left, level);
            },
            .ast_fn_call => {
                ast.print(root_idx, left, level);
            },
            .ast_if => {
                const if_symbol_idx = ast_node.idx;
                const if_symbol = IfTable.table.items[if_symbol_idx];
                indent(level);
                std.debug.print("ast_if (self_idx: {d}, if_table_idx: {d}, if_scope_idx: {d}, else_scope_idx {d}){{\n", .{ root_idx, if_symbol_idx, if_symbol.if_scope_idx, if_symbol.else_scope_idx });
                indent(level + 1);
                std.debug.print("if_expr {{\n", .{});
                ast.print(ast_node.left, left, level + 2);
                indent(level + 1);
                std.debug.print("}}\n", .{});
                const if_scope = MultiScopeTable.table.items[if_symbol.if_scope_idx];
                indent(level + 1);
                std.debug.print("if_scope {{\n", .{});
                for (if_scope.table.items) |idx| {
                    ast.print_block(idx, left, level + 2);
                }
                if (if_symbol.else_scope_idx != nan_u64) {
                    const else_scope = MultiScopeTable.table.items[if_symbol.else_scope_idx];
                    indent(level + 1);
                    std.debug.print("\n}} else_scope {{\n", .{});
                    for (else_scope.table.items) |idx| {
                        ast.print_block(idx, left, level + 2);
                    }
                }
                indent(level + 1);
                std.debug.print("}}\n", .{});
                indent(level);
                std.debug.print("}}\n", .{});
            },
            .ast_while => {
                const while_idx = ast_node.idx;
                indent(level);
                std.debug.print("ast_while (self_idx: {d}, while_scope_idx: {d}){{\n", .{ root_idx, while_idx });
                indent(level + 1);
                std.debug.print("while_expr {{\n", .{});
                ast.print(ast_node.left, left, level + 2);
                indent(level + 1);
                std.debug.print("}}\n", .{});
                const while_scope = MultiScopeTable.table.items[while_idx];
                indent(level + 1);
                std.debug.print("while_scope {{\n", .{});
                for (while_scope.table.items) |idx| {
                    ast.print_block(idx, left, level + 2);
                }
                indent(level + 1);
                std.debug.print("}}\n", .{});
                indent(level);
                std.debug.print("}}\n", .{});
            },
            else => {},
        }
    }

    pub fn print_ast(ast: *Ast, ast_roots: *const std.ArrayList(u32)) void {
        for (ast_roots.items) |root_idx| {
            const ast_node = ast.nodes.items[root_idx];
            switch (ast_node.type) {
                .ast_fn_block => {
                    const fn_block_idx = ast_node.idx;
                    const fn_block = FnTable.table.items[fn_block_idx];

                    std.debug.print("\nast_fn_block (self_idx: {d}, fn_table_idx: {d}){{\n", .{ root_idx, fn_block_idx });

                    const scope = MultiScopeTable.table.items[fn_block.scope_idx];
                    for (scope.table.items) |idx| {
                        ast.print_block(idx, 0, 1);
                    }
                    std.debug.print("}}\n", .{});
                },
                //                .ast_if => {
                //                    const if_symbol_idx = ast_node.idx;
                //                    const if_symbol = IfTable.table.items[if_symbol_idx];
                //                std.debug.print("ast_if (self_idx: {d}, if_table_idx: {d}, if_scope_idx: {d}, else_scope_idx {d}){{\n", .{ root_idx, if_symbol_idx, if_symbol.if_scope_idx, if_symbol.else_scope_idx });
                //                    const if_scope = MultiScopeTable.table.items[if_symbol.if_scope_idx];
                //                    for (if_scope.table.items) |idx| {
                //                        ast.print_block(idx, 0, 0);
                //                    }
                //                    std.debug.print("\n}} else {{\n", .{});
                //                    const else_scope = MultiScopeTable.table.items[if_symbol.else_scope_idx];
                //                    for (else_scope.table.items) |idx| {
                //                        ast.print_block(idx, 0, 0);
                //                    }
                //                    indent(0);
                //                    std.debug.print("\n}}\n", .{});
                //                },
                else => ast.print_block(root_idx, 0, 0),
            }
        }
    }
};
