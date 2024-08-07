const std = @import("std");
const Ast = @import("ast.zig").Ast;
const Node = @import("ast.zig").Node;
const Type = @import("ast.zig").Type;
const tokenizer = @import("tokenizer.zig");
const Token = tokenizer.Token;
const Tokenizer = tokenizer.Tokenizer;
const TokenType = tokenizer.TokenType;
const LocInfo = tokenizer.LocInfo;
const tables = @import("tables.zig");
const SymbolTable = tables.SymbolTable;
const SymbolType = tables.Type;
const ExprTypeTable = tables.ExprTypeTable;
const FnTable = tables.FnTable;
const FnCallTable = tables.FnCallTable;
const Parser = @import("parser.zig").Parser;

const nan_u32 = 0x7FC00000;

pub fn analyse_type_semantic(parser: *Parser, curr_node: u32) void {
    var node = &parser.ast.nodes.items[curr_node];
    const left_exist = node.left != nan_u32;
    const right_exist = node.right != nan_u32;

    if (left_exist) {
        parser.analyse_type_semantic(node.left);
    }
    if (right_exist) {
        parser.analyse_type_semantic(node.right);
    }

    // TODO: I forgot why I keep checking left/right exist for operations?
    switch (node.type) {
        .add, .sub, .mult, .div, .bool_not, .bool_and, .bool_or => {
            if (left_exist and right_exist) {
                var left_type: SymbolType = undefined;
                var right_type: SymbolType = undefined;
                const left_node: Node = parser.ast.nodes.items[node.left];
                const right_node: Node = parser.ast.nodes.items[node.right];
                switch (left_node.type) {
                    .identifier => {
                        const name: []u8 = parser.source[left_node.loc.start..left_node.loc.end];
                        if (SymbolTable.findByName(name)) |sym| {
                            left_type = sym.type;
                        } else {
                            unreachable;
                        }
                    },
                    .int_literal => left_type = .t_int,
                    .float_literal => left_type = .t_float,
                    .bool_literal => left_type = .t_bool,
                    .add, .sub, .mult, .div, .negate, .bool_not, .bool_and, .bool_or => {
                        left_type = ExprTypeTable.table.items[left_node.idx].type;
                    },
                    else => {
                        unreachable;
                    },
                }
                switch (right_node.type) {
                    .identifier => {
                        const name: []u8 = parser.source[right_node.loc.start..right_node.loc.end];
                        if (SymbolTable.findByName(name)) |sym| {
                            right_type = sym.type;
                        } else {
                            unreachable;
                        }
                    },
                    .int_literal => right_type = .t_int,
                    .float_literal => right_type = .t_float,
                    .bool_literal => right_type = .t_bool,
                    .add, .sub, .mult, .div, .negate, .bool_not, .bool_and, .bool_or => {
                        right_type = ExprTypeTable.table.items[right_node.idx].type;
                    },
                    else => {
                        unreachable;
                    },
                }
                if (left_type != right_type) {
                    parser.reportError(node.loc, "Types miss-match between '{s}' and '{s}'\n", .{ left_type.str(), right_type.str() }, false);
                    parser.reportError(left_node.loc, "Type '{s}' declared here:\n", .{left_type.str()}, false);
                    parser.reportError(right_node.loc, "Type '{s}' declared here:\n", .{right_type.str()}, true);
                }
                node.idx = ExprTypeTable.appendExprType(left_type);
            } else if (left_exist and !right_exist) {
                @panic("TODO!");
            } else if (right_exist and !left_exist) {
                @panic("TODO!");
            }
        },
        .negate => {
            // TODO: Remove this code duplication
            if (left_exist) {
                var left_type: SymbolType = undefined;
                const left_node: Node = parser.ast.nodes.items[node.left];
                switch (left_node.type) {
                    .identifier => {
                        const name: []u8 = parser.source[left_node.loc.start..left_node.loc.end];
                        if (SymbolTable.findByName(name)) |sym| {
                            left_type = sym.type;
                        } else {
                            unreachable;
                        }
                    },
                    .int_literal => left_type = .t_int,
                    .float_literal => left_type = .t_float,
                    .bool_literal => unreachable,
                    .add, .sub, .mult, .div => {
                        left_type = ExprTypeTable.table.items[left_node.idx].type;
                    },
                    else => unreachable,
                }
                node.idx = ExprTypeTable.appendExprType(left_type);
            }
        },
        else => {},
    }
}

// TODO: Doesn't properly handle identifiers and stuffs
pub fn analyse_chain_type(parser: *Parser, curr_node: u32) Node {
    const node = parser.ast.nodes.items[curr_node];
    var left_node: Node = undefined;
    var right_node: Node = undefined;
    if (node.left != nan_u32) {
        left_node = parser.analyse_chain_type(node.left);
    }

    if (node.right != nan_u32) {
        right_node = parser.analyse_chain_type(node.right);
    }

    switch (node.type) {
        .add, .sub, .mult, .div => {
            if (left_node.type != right_node.type and left_node.isNumberalLiteral() and right_node.isNumberalLiteral()) {
                parser.reportError(node.loc, "Types miss-match between '{s}' and '{s}'\n", .{ left_node.type.strType(), right_node.type.strType() }, false);
                parser.reportError(left_node.loc, "Type '{s}' declared here:\n", .{left_node.type.strType()}, false);
                parser.reportError(right_node.loc, "Type '{s}' declared here:\n", .{right_node.type.strType()}, true);
            } else if (left_node.type == .bool_literal or right_node.type == .bool_literal) {
                parser.reportError(node.loc, "Unexpected type(s) '{s}' and '{s}'\n", .{ left_node.type.strType(), right_node.type.strType() }, false);
                parser.reportError(left_node.loc, "Type '{s}' declared here:\n", .{left_node.type.strType()}, false);
                parser.reportError(right_node.loc, "Type '{s}' declared here:\n", .{right_node.type.strType()}, true);
            } else {
                var new_node = left_node;
                new_node.loc.start = left_node.loc.start;
                new_node.loc.end = right_node.loc.end;
                return new_node;
            }
        },
        .bool_and, .bool_or => {
            if (left_node.isTypeLiteral() and right_node.isTypeLiteral() and left_node.type != .bool_literal or right_node.type != .bool_literal) {
                parser.reportError(node.loc, "Types miss-match, expected type bool(s) found '{s}' and '{s}'\n", .{ left_node.type.strType(), right_node.type.strType() }, false);
                parser.reportError(left_node.loc, "Type '{s}' declared here:\n", .{left_node.type.strType()}, false);
                parser.reportError(right_node.loc, "Type '{s}' declared here:\n", .{right_node.type.strType()}, true);
            } else {
                var new_node = left_node;
                new_node.loc.start = left_node.loc.start;
                new_node.loc.end = right_node.loc.end;
                return new_node;
            }
        },
        .int_literal, .float_literal, .bool_literal => {
            return node;
        },
        else => {},
    }
    return node;
}

// TODO: IDK why I made this and what is special about this
pub fn analyse_bool(parser: *Parser, curr_node: u32) void {
    const node = parser.ast.nodes.items[curr_node];

    if (node.left != nan_u32) {
        parser.analyse_bool(node.left);
    }

    if (node.right != nan_u32) {
        parser.analyse_bool(node.right);
    }

    switch (node.type) {
        .bool_not => {
            if (node.left != nan_u32 and node.right == nan_u32) {
                const left_node = parser.ast.nodes.items[node.left];
                if (left_node.type != .bool_literal) {
                    const loc: LocInfo = .{ .start = node.loc.start, .end = left_node.loc.end, .line = node.loc.line };
                    parser.reportError(loc, "Cannot use operator '!' on type '{s}', expected type 'bool'\n", .{left_node.type.strType()}, true);
                }
            }
        },
        .negate => {
            if (node.left != nan_u32 and node.right == nan_u32) {
                const left_node = parser.ast.nodes.items[node.left];
                if (left_node.type != .int_literal and left_node.type != .float_literal) {
                    const loc: LocInfo = .{ .start = node.loc.start, .end = left_node.loc.end, .line = node.loc.line };
                    parser.reportError(loc, "Cannot use operator '-' on type '{s}', expected type 'float' or type 'int'\n", .{left_node.type.strType()}, true);
                }
            }
        },
        .greater, .lesser, .greater_equal, .lesser_equal => {
            if (node.left != nan_u32 and node.right != nan_u32) {
                const left_node = parser.ast.nodes.items[node.left];
                const right_node = parser.ast.nodes.items[node.right];
                if (left_node.isTypeLiteral() and right_node.isTypeLiteral()) {
                    if (left_node.type != right_node.type) {
                        parser.reportError(node.loc, "Types miss-match between '{s}' and '{s}'\n", .{ left_node.type.strType(), right_node.type.strType() }, false);
                        parser.reportError(left_node.loc, "Type '{s}' declared here:\n", .{left_node.type.strType()}, false);
                        parser.reportError(right_node.loc, "Type '{s}' declared here:\n", .{right_node.type.strType()}, true);
                    } else if (left_node.type == .bool_literal or right_node.type == .bool_literal) {
                        parser.reportError(node.loc, "Unexpected type(s) '{s}' and '{s}'\n", .{ left_node.type.strType(), right_node.type.strType() }, false);
                        parser.reportError(left_node.loc, "Type '{s}' declared here:\n", .{left_node.type.strType()}, false);
                        parser.reportError(right_node.loc, "Type '{s}' declared here:\n", .{right_node.type.strType()}, true);
                    }
                }
                if (left_node.isComparisonOp() and node.isComparisonOp()) {
                    const loc: LocInfo = .{ .start = left_node.loc.start, .end = node.loc.end, .line = left_node.loc.line };
                    parser.reportError(loc, "Comparision operators cannot be chained:\n", .{}, false);
                    parser.reportError(left_node.loc, "First operator declared here:\n", .{}, false);
                    parser.reportError(node.loc, "Second operator declared here:\n", .{}, true);
                }
            }
        },
        .equal_equal, .not_equal => {
            if (node.left != nan_u32) {
                const left_node = parser.ast.nodes.items[node.left];
                if (left_node.isComparisonOp() and node.isComparisonOp()) {
                    const loc: LocInfo = .{ .start = left_node.loc.start, .end = node.loc.end, .line = left_node.loc.line };
                    parser.reportError(loc, "Comparision operators cannot be chained:\n", .{}, false);
                    parser.reportError(left_node.loc, "First operator declared here:\n", .{}, false);
                    parser.reportError(node.loc, "Second operator declared here:\n", .{}, true);
                }

                if (node.right != nan_u32) {
                    const right_node = parser.ast.nodes.items[node.right];
                    if (left_node.type != right_node.type and left_node.isTypeLiteral() and right_node.isTypeLiteral()) {
                        parser.reportError(node.loc, "Types miss-match between '{s}' and '{s}'\n", .{ left_node.type.strType(), right_node.type.strType() }, false);
                        parser.reportError(left_node.loc, "Type '{s}' declared here:\n", .{left_node.type.strType()}, false);
                        parser.reportError(right_node.loc, "Type '{s}' declared here:\n", .{right_node.type.strType()}, true);
                    }
                }
            }
        },
        else => {},
    }
}

pub fn analyze(parser: *Parser) void {
    // Analyze
    for (parser.ast_roots.items) |root_idx| {
        const ast_node = parser.ast.nodes.items[root_idx];
        switch (ast_node.type) {
            .var_stmt => {
                const symbol_idx = ast_node.idx;
                const symbol_entry = SymbolTable.varTable.get(symbol_idx);
                //                    parser.analyse_bool(symbol_entry.expr_node);
                //                    _ = parser.analyse_chain_type(symbol_entry.expr_node);
                parser.analyse_type_semantic(symbol_entry.expr_node);
            },
            .print_stmt => {
                const left_idx = ast_node.left;
                //                    parser.analyse_bool(left_idx);
                //                    _ = parser.analyse_chain_type(left_idx);
                parser.analyse_type_semantic(left_idx);
            },
            .assign_stmt => {
                const right_idx = ast_node.right;
                //                    parser.analyse_bool(right_idx);
                //                    _ = parser.analyse_chain_type(right_idx);
                parser.analyse_type_semantic(right_idx);
            },
            else => {},
        }
    }
}
