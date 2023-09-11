const std = @import("std");
const LocInfo = @import("tokenizer.zig").LocInfo;

pub const Type = enum {
    int_literal,
    float_literal,
    bool_literal,
    bool_not,
    bool_and,
    bool_or,
    greater,
    lesser,
    greater_equal,
    lesser_equal,
    equal_equal,
    not_equal,
    negate,
    mult,
    div,
    add,
    sub,
    identifier,
    var_stmt,
    print_stmt,
    assign_stmt,

    pub fn strType(ast_type: Type) []const u8 {
        switch (ast_type) {
            .int_literal => return "int",
            .float_literal => return "float",
            .bool_literal => return "bool",
            else => {
                unreachable;
            },
        }
    }

    pub fn str(ast_type: Type) []const u8 {
        switch (ast_type) {
            .int_literal => return "int_literal",
            .float_literal => return "float_literal",
            .bool_literal => return "bool_literal",
            .bool_not => return "bool_not",
            .bool_and => return "bool_and",
            .bool_or => return "bool_or",
            .greater => return "greater",
            .lesser => return "lesser",
            .greater_equal => return "greater_equal",
            .lesser_equal => return "lesser_equal",
            .equal_equal => return "equal_equal",
            .not_equal => return "not_equal",
            .negate => return "negate",
            .mult => return "mult",
            .div => return "div",
            .add => return "add",
            .sub => return "sub",
            .identifier => return "identifier",
            .var_stmt => return "var_stmt",
            .print_stmt => return "print_stmt",
            .assign_stmt => return "assign_stmt"
        }
    }
};

pub const Node = struct {
    loc: LocInfo,
    type: Type,
    symbol_idx: usize,
    left: u32,
    right: u32,

    pub fn isTypeLiteral(node: Node) bool {
        return node.type == .int_literal or node.type == .float_literal or node.type == .bool_literal;
    }

    pub fn isNumberalLiteral(node: Node) bool {
        return node.type == .int_literal or node.type == .float_literal;
    }

    pub fn isComparisonOp(node: Node) bool {
        return node.type == .greater or node.type == .lesser or node.type == .greater_equal or node.type == .lesser_equal or node.type == .equal_equal or node.type == .not_equal;
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

    pub fn addNode(ast: *Ast, expr_type: Type, symbol_idx: usize, left: u32, right: u32, loc: LocInfo) u32 {
        const idx: u32 = @as(u32, @intCast(ast.nodes.items.len));
        ast.nodes.append(.{ .type = expr_type, .symbol_idx = symbol_idx, .left = left, .right = right, .loc = loc }) catch |err| {
            std.debug.print("Error while adding node: {any}", .{err});
        };
        return idx;
    }

    pub fn addUnaryNode(ast: *Ast, expr_type: Type, symbol_idx:usize, left: u32, loc: LocInfo) u32 {
        return ast.addNode(expr_type, symbol_idx, left, std.math.nan_u32, loc);
    }

    pub fn addLiteralNode(ast: *Ast, expr_type: Type, symbol_idx: usize, loc: LocInfo) u32 {
        return ast.addNode(expr_type, symbol_idx, std.math.nan_u32, std.math.nan_u32, loc);
    }

    pub fn print(ast: *Ast, node: u32, left: u8, level: u32) void {
        if (ast.nodes.items[node].right != std.math.nan_u32) {
            ast.print(ast.nodes.items[node].right, 2, level + 1);
        }

        for (0..level) |i| {
            std.debug.print("{s}", .{if (i == level - 1) " |- " else "  "});
        }

        if (left == 1) {
            std.debug.print("{s} (left)\n", .{ast.nodes.items[node].type.str()});
        } else if (left == 2) {
            std.debug.print("{s} (right)\n", .{ast.nodes.items[node].type.str()});
        } else {
            std.debug.print("{s} (root)\n", .{ast.nodes.items[node].type.str()});
        }

        if (ast.nodes.items[node].left != std.math.nan_u32) {
            ast.print(ast.nodes.items[node].left, 1, level + 1);
        }
    }
};
