const std = @import("std");
const Ast = @import("ast.zig").Ast;
const Node = @import("ast.zig").Node;
const Type = @import("ast.zig").Type;
const tokenizer = @import("tokenizer.zig");
const Token = tokenizer.Token;
const Tokenizer = tokenizer.Tokenizer;
const TokenType = tokenizer.TokenType;
const LocInfo = tokenizer.LocInfo;

const nan_u32 = std.math.nan_u32;

pub const Parser = struct {
    current: u32,
    ast: Ast,
    source: []u8,
    source_name: []const u8,
    token_pool: std.ArrayList(Token),

    pub fn init(allocator: std.mem.Allocator, _tokenizer: Tokenizer) Parser {
        return .{
            .current = 0,
            .ast = Ast.init(allocator),
            .source = _tokenizer.source,
            .source_name = _tokenizer.source_name,
            .token_pool = _tokenizer.pool,
        };
    }

    pub fn deinit(parser: *Parser) void {
        parser.ast.deinit();
    }

    fn getNode(parser: *Parser, index: u32) Node {
        return parser.ast.nodes.items[index];
    }

    fn peek(parser: *Parser) Token {
        return parser.token_pool.items[parser.current];
    }

    fn peekPrev(parser: *Parser) Token {
        return parser.token_pool.items[parser.current - 1];
    }

    fn consume(parser: *Parser) Token {
        const token = parser.peek();
        parser.current += 1;
        return token;
    }

    fn match(parser: *Parser, token_type: TokenType) bool {
        if (parser.peek().type != token_type) return false;
        _ = parser.consume();
        return true;
    }

    fn primary(parser: *Parser) u32 {
        if (parser.match(.int)) {
            const int_lit = parser.peekPrev();
            return parser.ast.addLiteralNode(.int_literal, int_lit.loc);
        }
        if (parser.match(.float)) {
            const float_lit = parser.peekPrev();
            return parser.ast.addLiteralNode(.float_literal, float_lit.loc);
        }
        if (parser.match(.true) or parser.match(.false)) {
            const bool_lit = parser.peekPrev();
            return parser.ast.addLiteralNode(.bool_literal, bool_lit.loc);
        }
        if (parser.match(.left_paren)) {
            var expr: u32 = parser.expression();
            if (!parser.match(.right_paren)) std.debug.print("Expected ')' after expression", .{});
            return expr;
        }

        const loc = parser.peek().loc;
        parser.reportError(loc, "Unknow literal '{s}' found:\n", .{parser.source[loc.start..loc.end]}, true);
        return nan_u32;
    }

    fn unary(parser: *Parser) u32 {
        if (parser.match(.minus)) {
            const minus = parser.peekPrev();
            const node = parser.unary();
            const loc: LocInfo = .{
                .start = minus.loc.start,
                .end = parser.getNode(node).loc.end,
                .line = minus.loc.line,
            };
            return parser.ast.addUnaryNode(.negate, node, loc);
        }
        if (parser.match(.not)) {
            const not = parser.peekPrev();
            const node = parser.unary();
            const loc: LocInfo = .{
                .start = not.loc.start,
                .end = parser.getNode(node).loc.end,
                .line = not.loc.line,
            };
            return parser.ast.addUnaryNode(.bool_not, node, loc);
        }
        return parser.primary();
    }

    fn factor(parser: *Parser) u32 {
        var left = parser.unary();
        while (parser.match(.star) or parser.match(.slash)) {
            const op_token = parser.peekPrev();
            const op_type: Type = if (op_token.type == .star) .mult else .div;
            const right = parser.unary();
            left = parser.ast.addNode(op_type, left, right, op_token.loc);
        }
        return left;
    }

    fn term(parser: *Parser) u32 {
        var left = parser.factor();
        while (parser.match(.plus) or parser.match(.minus)) {
            const op_token = parser.peekPrev();
            const op_type: Type = if (op_token.type == .plus) .add else .sub;
            const right = parser.factor();
            left = parser.ast.addNode(op_type, left, right, op_token.loc);
        }
        return left;
    }

    fn comparision(parser: *Parser) u32 {
        var left = parser.term();
        while (parser.match(.greater) or parser.match(.lesser) or parser.match(.greater_equal) or parser.match(.lesser_equal)) {
            const op_token = parser.peekPrev();
            var op_type: Type = undefined;
            switch (op_token.type) {
                .greater => op_type = .greater,
                .lesser => op_type = .lesser,
                .greater_equal => op_type = .greater_equal,
                .lesser_equal => op_type = .lesser_equal,
                else => {},
            }
            const right = parser.term();
            left = parser.ast.addNode(op_type, left, right, op_token.loc);
        }
        return left;
    }

    fn equality(parser: *Parser) u32 {
        var left = parser.comparision();
        while (parser.match(.equal_equal) or parser.match(.not_equal)) {
            const op_token = parser.peekPrev();
            const op_type: Type = if (op_token.type == .equal_equal) .equal_equal else .not_equal;
            const right = parser.comparision();
            left = parser.ast.addNode(op_type, left, right, op_token.loc);
        }
        return left;
    }

    fn logical(parser: *Parser) u32 {
        var left = parser.equality();
        while (parser.match(.amp_amp) or parser.match(.pipe_pipe)) {
            const op_token = parser.peekPrev();
            const op_type: Type = if (op_token.type == .amp_amp) .bool_and else .bool_or;
            const right = parser.equality();
            left = parser.ast.addNode(op_type, left, right, op_token.loc);
        }
        return left;
    }

    fn expression(parser: *Parser) u32 {
        return parser.logical();
    }

    fn reportError(parser: *Parser, loc: LocInfo, comptime str: []const u8, args: anytype, exit: bool) void {
        std.debug.print("{s}:{d}: ", .{ parser.source_name, loc.line });
        std.debug.print(str, args);

        var error_line_offset: u32 = 0;
        var line_counter: u32 = 0;
        // Get offset to the line containing error.
        while (error_line_offset < parser.source.len) : (error_line_offset += 1) {
            if (line_counter == loc.line) break;
            if (parser.source[error_line_offset] == '\n') line_counter += 1;
        }
        // Print the line
        var i: u32 = error_line_offset;
        while (i < parser.source.len and parser.source[i] != '\n') : (i += 1) {
            std.debug.print("{c}", .{parser.source[i]});
        }
        std.debug.print("\n", .{});
        // Print the fancy pointer
        i = error_line_offset;
        while (i < parser.source.len and parser.source[i] != '\n') : (i += 1) {
            if (i >= loc.start and i <= loc.end - 1) {
                std.debug.print("^", .{});
            } else {
                std.debug.print("-", .{});
            }
        }
        std.debug.print("\n", .{});

        if (exit) std.process.exit(1);
    }

    pub fn analyse(parser: *Parser, curr_node: u32) void {
        const node = parser.ast.nodes.items[curr_node];

        if (node.left != nan_u32) {
            parser.analyse(node.left);
        }

        if (node.right != nan_u32) {
            parser.analyse(node.right);
        }

        switch (node.type) {
            .add, .sub, .mult, .div => {
                if (node.right != nan_u32 and node.right != nan_u32) {
                    const left_node = parser.ast.nodes.items[node.left];
                    const right_node = parser.ast.nodes.items[node.right];
                    if (left_node.type != right_node.type and left_node.isTypeLiteral() and right_node.isTypeLiteral()) {
                        parser.reportError(node.loc, "Types miss-match between '{s}' and '{s}'\n", .{ left_node.type.strType(), right_node.type.strType() }, false);
                        parser.reportError(left_node.loc, "Type '{s}' declared here:\n", .{left_node.type.strType()}, false);
                        parser.reportError(right_node.loc, "Type '{s}' declared here:\n", .{right_node.type.strType()}, true);
                    }
                }
            },
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
                    if (left_node.type != right_node.type and left_node.isNumberalLiteral() and right_node.isNumberalLiteral()) {
                        parser.reportError(node.loc, "Types miss-match between '{s}' and '{s}'\n", .{ left_node.type.strType(), right_node.type.strType() }, false);
                        parser.reportError(left_node.loc, "Type '{s}' declared here:\n", .{left_node.type.strType()}, false);
                        parser.reportError(right_node.loc, "Type '{s}' declared here:\n", .{right_node.type.strType()}, true);
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
            .bool_and, .bool_or => {
                if (node.left != nan_u32 and node.right != nan_u32) {
                    const left_node = parser.ast.nodes.items[node.left];
                    const right_node = parser.ast.nodes.items[node.right];
                    if (left_node.type != .bool_literal or right_node.type != .bool_literal) {
                        parser.reportError(node.loc, "Types miss-match, expected type bool(s) found '{s}' and '{s}'\n", .{ left_node.type.strType(), right_node.type.strType() }, false);
                        parser.reportError(left_node.loc, "Type '{s}' declared here:\n", .{left_node.type.strType()}, false);
                        parser.reportError(right_node.loc, "Type '{s}' declared here:\n", .{right_node.type.strType()}, true);
                    }
                }
            },
            else => {},
        }
    }

    pub fn parse(parser: *Parser) u32 {
        const expr = parser.expression();
        if (!parser.match(.eof)) {
            const loc = parser.peek().loc;
            parser.reportError(loc, "Expected end of expression, found '{s}':\n", .{parser.source[loc.start..loc.end]}, true);
        }
        parser.analyse(expr);
        return expr;
    }
};
