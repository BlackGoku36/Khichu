const std = @import("std");
const LocInfo = @import("tokenizer.zig").LocInfo;

const nan_u32 = 0x7FC00000;

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
    fn_block,
    fn_call,

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
            .assign_stmt => return "assign_stmt",
            .fn_block => return "fn_block",
            .fn_call => return "fn_call",
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

    pub fn print(ast: *Ast, node: u32, left: u8, level: u32) void {
        if (ast.nodes.items[node].right != nan_u32) {
            ast.print(ast.nodes.items[node].right, 2, level + 1);
        }

        for (0..level) |i| {
            std.debug.print("{s}", .{if (i == level - 1) " |- " else "  "});
        }

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
};
