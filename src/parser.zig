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
const FnParameterSymbol = tables.FnParameterSymbol;
const IfSymbol = tables.IfSymbol;
const IfTable = tables.IfTable;
const MultiScopeTable = tables.MultiScopeTable;
const ScopeTable = tables.ScopeTable;

const nan_u32 = 0x7FC00000;
const nan_u64 = 0x7FF8000000000000;

pub const Parser = struct {
    current: u32,
    ast: Ast,
    source: []u8,
    source_name: []const u8,
    token_pool: std.ArrayList(Token),
    ast_roots: std.ArrayList(u32),

    pub fn init(allocator: std.mem.Allocator, _tokenizer: Tokenizer) Parser {
        return .{
            .current = 0,
            .ast = Ast.init(allocator),
            .source = _tokenizer.source,
            .source_name = _tokenizer.source_name,
            .token_pool = _tokenizer.pool,
            .ast_roots = std.ArrayList(u32).init(allocator),
        };
    }

    pub fn deinit(parser: *Parser) void {
        parser.ast.deinit();
        parser.ast_roots.deinit();
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
        if (parser.match(.tok_int)) {
            const int_lit = parser.peekPrev();
            return parser.ast.addLiteralNode(.ast_int_literal, nan_u32, int_lit.loc);
        }
        if (parser.match(.tok_float)) {
            const float_lit = parser.peekPrev();
            return parser.ast.addLiteralNode(.ast_float_literal, nan_u32, float_lit.loc);
        }
        if (parser.match(.tok_true) or parser.match(.tok_false)) {
            const bool_lit = parser.peekPrev();
            return parser.ast.addLiteralNode(.ast_bool_literal, nan_u32, bool_lit.loc);
        }
        if (parser.match(.tok_identifier)) {
            const ident = parser.peekPrev();
            return parser.ast.addLiteralNode(.ast_identifier, nan_u32, ident.loc);
        }
        if (parser.match(.tok_left_paren)) {
            const left_paren = parser.peekPrev();
            const expr: u32 = parser.expression();
            if (!parser.match(.tok_right_paren)) parser.reportError(left_paren.loc, "Expected ')' after expression\n", .{}, true);
            return expr;
        }

        const loc = parser.peek().loc;
        parser.reportError(loc, "Unknow literal '{s}' found:\n", .{parser.source[loc.start..loc.end]}, true);
        return nan_u32;
    }

    fn call(parser: *Parser) u32 {
        var expr = parser.primary();

        while (true) {
            const fn_name_token = parser.peekPrev();

            if (parser.match(.tok_left_paren)) {
                var args: [10]usize = .{0} ** 10;
                var args_len: usize = 0;
                if (parser.peek().type != .tok_right_paren) {
                    while (true) {
                        if (args_len + 1 >= 10) {
                            //TODO: Same error for when function is declared with 10+ parameters
                            parser.reportError(parser.peekPrev().loc, "Amount of arguments passed exceeded limit 10.\n", .{}, true);
                        }

                        const argument = parser.expression();
                        args[args_len] = argument;
                        args_len += 1;

                        if (!parser.match(.tok_comma)) break;
                    }
                }
                if (!parser.match(.tok_right_paren)) {
                    parser.reportError(parser.peekPrev().loc, "Expected ')' after expression\n", .{}, true);
                }
                const fn_name_node = expr;
                const fn_idx = FnCallTable.appendFunction(.{ .name_node = fn_name_node, .arguments = args, .arguments_len = args_len });
                const loc: LocInfo = .{ .start = fn_name_token.loc.start, .end = fn_name_token.loc.end, .line = fn_name_token.loc.line };
                expr = parser.ast.addLiteralNode(.ast_fn_call, fn_idx, loc);
            } else {
                break;
            }
        }

        return expr;
    }

    fn unary(parser: *Parser) u32 {
        if (parser.match(.tok_minus)) {
            const minus = parser.peekPrev();
            const node = parser.unary();
            const loc: LocInfo = .{
                .start = minus.loc.start,
                .end = parser.getNode(node).loc.end,
                .line = minus.loc.line,
            };
            return parser.ast.addUnaryNode(.ast_negate, nan_u32, node, loc);
        }
        if (parser.match(.tok_not)) {
            const not = parser.peekPrev();
            const node = parser.unary();
            const loc: LocInfo = .{
                .start = not.loc.start,
                .end = parser.getNode(node).loc.end,
                .line = not.loc.line,
            };
            return parser.ast.addUnaryNode(.ast_bool_not, nan_u32, node, loc);
        }
        return parser.call();
    }

    fn factor(parser: *Parser) u32 {
        var left = parser.unary();
        while (parser.match(.tok_star) or parser.match(.tok_slash)) {
            const op_token = parser.peekPrev();
            const op_type: Type = if (op_token.type == .tok_star) .ast_mult else .ast_div;
            const right = parser.unary();
            left = parser.ast.addNode(op_type, nan_u32, left, right, op_token.loc);
        }
        return left;
    }

    fn term(parser: *Parser) u32 {
        var left = parser.factor();
        while (parser.match(.tok_plus) or parser.match(.tok_minus)) {
            const op_token = parser.peekPrev();
            const op_type: Type = if (op_token.type == .tok_plus) .ast_add else .ast_sub;
            const right = parser.factor();
            left = parser.ast.addNode(op_type, nan_u32, left, right, op_token.loc);
        }
        return left;
    }

    fn comparision(parser: *Parser) u32 {
        var left = parser.term();
        while (parser.match(.tok_greater) or parser.match(.tok_lesser) or parser.match(.tok_greater_equal) or parser.match(.tok_lesser_equal)) {
            const op_token = parser.peekPrev();
            var op_type: Type = undefined;
            switch (op_token.type) {
                .tok_greater => op_type = .ast_greater,
                .tok_lesser => op_type = .ast_lesser,
                .tok_greater_equal => op_type = .ast_greater_equal,
                .tok_lesser_equal => op_type = .ast_lesser_equal,
                else => {},
            }
            const right = parser.term();
            left = parser.ast.addNode(op_type, nan_u32, left, right, op_token.loc);
        }
        return left;
    }

    fn equality(parser: *Parser) u32 {
        var left = parser.comparision();
        while (parser.match(.tok_equal_equal) or parser.match(.tok_not_equal)) {
            const op_token = parser.peekPrev();
            const op_type: Type = if (op_token.type == .tok_equal_equal) .ast_equal_equal else .ast_not_equal;
            const right = parser.comparision();
            left = parser.ast.addNode(op_type, nan_u32, left, right, op_token.loc);
        }
        return left;
    }

    fn logical(parser: *Parser) u32 {
        var left = parser.equality();
        while (parser.match(.tok_amp_amp) or parser.match(.tok_pipe_pipe)) {
            const op_token = parser.peekPrev();
            const op_type: Type = if (op_token.type == .tok_amp_amp) .ast_bool_and else .ast_bool_or;
            const right = parser.equality();
            left = parser.ast.addNode(op_type, nan_u32, left, right, op_token.loc);
        }
        return left;
    }

    fn assignment(parser: *Parser) u32 {
        const ident_idx = parser.logical();
        const ident_node = parser.ast.nodes.items[ident_idx];
        if (parser.match(.tok_equal)) {
            if (ident_node.type != .ast_identifier) {
                parser.reportError(ident_node.loc, "Expected 'identifier' before '=', found '{s}'.\n", .{ident_node.type.str()}, true);
            }
            const expr_node = parser.assignment();
            const loc: LocInfo = .{ .start = ident_node.loc.start, .end = parser.peekPrev().loc.end, .line = ident_node.loc.line };
            return parser.ast.addNode(.ast_assign_stmt, nan_u32, ident_idx, expr_node, loc);
        }
        return ident_idx;
    }

    fn expression(parser: *Parser) u32 {
        return parser.assignment();
    }

    fn expressionStatement(parser: *Parser) u32 {
        const expr = parser.expression();
        if (!parser.match(.tok_semi_colon)) {
            parser.reportError(parser.peekPrev().loc, "Expected ';' after 'expression', found '{s}'.\n", .{parser.peekPrev().type.str()}, true);
        }
        return expr;
    }

    //TODO: check if this can be cleaned up
    fn varStatement(parser: *Parser) u32 {
        const var_token = parser.consume(); //Consume 'var' token
        if (!parser.match(.tok_identifier)) {
            parser.reportError(var_token.loc, "Expected identifier after 'var', found '{s}'.\n", .{parser.peekPrev().type.str()}, true);
        }

        const ident = parser.peekPrev();

        const var_exist = SymbolTable.exists(parser.source[ident.loc.start..ident.loc.end]);
        if (var_exist) {
            parser.reportError(ident.loc, "Variable named '{s}' already exists.\n", .{parser.source[ident.loc.start..ident.loc.end]}, true);
        }

        if (!parser.match(.tok_colon)) {
            parser.reportError(parser.peekPrev().loc, "Expected ':' after 'identifier' and before 'type', found '{s}'.\n", .{parser.peekPrev().type.str()}, true);
        }

        const type_token = parser.consume();
        if (type_token.type != .tok_int_type and type_token.type != .tok_float_type and type_token.type != .tok_bool_type) {
            parser.reportError(type_token.loc, "Expected 'type' after ':' and before '=', found '{s}'.\n", .{type_token.type.str()}, true);
        }

        if (!parser.match(.tok_equal)) {
            parser.reportError(parser.peekPrev().loc, "Expected '=' after 'type' and before 'expression', found '{s}'.\n", .{parser.peekPrev().type.str()}, true);
        }

        const expr_node = parser.expressionStatement();

        const symbol_type: SymbolType = typeTokenToSymbolType(type_token);

        const symbol_idx = SymbolTable.appendVar(.{ .name = parser.source[ident.loc.start..ident.loc.end], .type = symbol_type, .expr_node = expr_node });

        const loc: LocInfo = .{ .start = var_token.loc.start, .end = parser.peekPrev().loc.end, .line = var_token.loc.line };
        return parser.ast.addLiteralNode(.ast_var_stmt, symbol_idx, loc);
    }

    fn printStatement(parser: *Parser) u32 {
        const print_token = parser.consume();
        if (!parser.match(.tok_left_paren)) {
            parser.reportError(parser.peekPrev().loc, "Expected '(' after 'print', found '{s}'.\n", .{parser.peekPrev().type.str()}, true);
        }
        const expr_node = parser.expression();
        if (!parser.match(.tok_right_paren)) {
            parser.reportError(parser.peekPrev().loc, "Expected ')' after 'expression', found '{s}'.\n", .{parser.peekPrev().type.str()}, true);
        }
        if (!parser.match(.tok_semi_colon)) {
            parser.reportError(parser.peekPrev().loc, "Expected ';' at end of statement, found '{s}'.\n", .{parser.peekPrev().type.str()}, true);
        }
        const loc: LocInfo = .{ .start = print_token.loc.start, .end = parser.peekPrev().loc.end, .line = print_token.loc.line };
        return parser.ast.addUnaryNode(.ast_print_stmt, nan_u32, expr_node, loc);
    }

    pub fn block(parser: *Parser, scope: *ScopeTable) void {
        if (!parser.match(.tok_left_brace)) {
            parser.reportError(parser.peekPrev().loc, "Expected '{{' at end of statement, found '{s}'.\n", .{parser.peekPrev().type.str()}, true);
        }
        while ((parser.peek().type != .tok_right_brace) and (parser.peek().type != .tok_eof)) {
            switch (parser.peek().type) {
                .tok_var => {
                    scope.appendNode(parser.varStatement());
                },
                .tok_print => {
                    scope.appendNode(parser.printStatement());
                },
                .tok_return => {
                    scope.appendNode(parser.functionReturn());
                },
                .tok_if => {
                    scope.appendNode(parser.ifStatement());
                },
                else => {
                    scope.appendNode(parser.expressionStatement());
                },
            }
        }
        if (!parser.match(.tok_right_brace)) {
            parser.reportError(parser.peekPrev().loc, "Expected '}}' at end of statement, found '{s}'.\n", .{parser.peekPrev().type.str()}, true);
        }
    }

    fn functionReturn(parser: *Parser) u32 {
        const return_token = parser.consume();
        const expr_node = parser.expression();
        if (!parser.match(.tok_semi_colon)) {
            parser.reportError(parser.peekPrev().loc, "Expected ';' at end of statement, found '{s}'.\n", .{parser.peekPrev().type.str()}, true);
        }
        const loc: LocInfo = .{ .start = return_token.loc.start, .end = parser.peekPrev().loc.end, .line = return_token.loc.line };
        return parser.ast.addUnaryNode(.ast_fn_return, nan_u32, expr_node, loc);
    }

    fn functionBlock(parser: *Parser) u32 {
        const fn_token = parser.consume();
        const fn_name_token = parser.consume();
        if (fn_name_token.type != .tok_identifier) {
            parser.reportError(parser.peekPrev().loc, "Expected name of function after 'fn', found '{s}'.\n", .{parser.peekPrev().type.str()}, true);
        }
        if (!parser.match(.tok_left_paren)) {
            parser.reportError(parser.peekPrev().loc, "Expected '(' after 'print', found '{s}'.\n", .{parser.peekPrev().type.str()}, true);
        }

        const parameter_start = FnTable.parameters.items.len;
        var parameter_size: usize = 0;

        if (parser.peek().type != .tok_right_paren) {
            while (true) {
                const parameter_identifier = parser.peek();
                if (!parser.match(.tok_identifier)) {
                    parser.reportError(parameter_identifier.loc, "Expected name of parameter after '(' and before ':', found '{s}'.\n", .{parameter_identifier.type.str()}, true);
                }
                if (!parser.match(.tok_colon)) {
                    parser.reportError(parameter_identifier.loc, "Expected ':' after parameter name and before type, found '{s}'.\n", .{parameter_identifier.type.str()}, true);
                }
                const parameter_type_token = parser.consume();
                if (parameter_type_token.type != .tok_int_type and parameter_type_token.type != .tok_float_type and parameter_type_token.type != .tok_bool_type) {
                    parser.reportError(parameter_identifier.loc, "Expected type after ':' and before ')', found '{s}'.\n", .{parameter_identifier.type.str()}, true);
                }

                const parameter_name_node = parser.ast.addLiteralNode(.ast_identifier, nan_u32, parameter_identifier.loc);

                const parameter_type: SymbolType = typeTokenToSymbolType(parameter_type_token);

                FnTable.parameters.append(.{ .name_node = parameter_name_node, .parameter_type = parameter_type }) catch |err| {
                    std.debug.print("Unable to create entry in FnTable (parameters): {}", .{err});
                };
                parameter_size += 1;

                if (!parser.match(.tok_comma)) {
                    break;
                }
            }
        }

        if (!parser.match(.tok_right_paren)) {
            parser.reportError(parser.peekPrev().loc, "Expected ')' after 'expression', found '{s}'.\n", .{parser.peekPrev().type.str()}, true);
        }

        const fn_return_type_token = parser.consume();
        if (fn_return_type_token.type != .tok_int_type and fn_return_type_token.type != .tok_float_type and fn_return_type_token.type != .tok_bool_type and fn_return_type_token.type != .tok_void_type) {
            parser.reportError(fn_return_type_token.loc, "Expected 'type' after ')' and before '{{', found '{s}'.\n", .{fn_return_type_token.type.str()}, true);
        }

        const return_symbol_type: SymbolType = typeTokenToSymbolType(fn_return_type_token);

        const scope_idx = MultiScopeTable.createScope();
        const scope = &MultiScopeTable.table.items[scope_idx];
        parser.block(scope);

        const fn_name_node = parser.ast.addLiteralNode(.ast_identifier, nan_u32, fn_name_token.loc);
        const fn_idx = FnTable.appendFunction(.{ .name_node = fn_name_node, .return_type = return_symbol_type, .parameter_start = parameter_start, .parameter_end = parameter_start + parameter_size, .scope_idx = scope_idx });
        const loc: LocInfo = .{ .start = fn_token.loc.start, .end = fn_return_type_token.loc.end, .line = fn_token.loc.line };
        return parser.ast.addLiteralNode(.ast_fn_block, fn_idx, loc);
    }

    fn ifStatement(parser: *Parser) u32 {
        const if_token = parser.consume();
        if (!parser.match(.tok_left_paren)) {
            parser.reportError(parser.peekPrev().loc, "Expected '(' after 'if', found '{s}'.\n", .{parser.peekPrev().type.str()}, true);
        }
        const expr = parser.expression();
        if (!parser.match(.tok_right_paren)) {
            parser.reportError(parser.peekPrev().loc, "Expected ')' after expression, found '{s}'.\n", .{parser.peekPrev().type.str()}, true);
        }
        const if_scope_idx = MultiScopeTable.createScope();
        const if_scope = &MultiScopeTable.table.items[if_scope_idx];
        parser.block(if_scope);

        var else_scope_idx: usize = nan_u64;
        if (parser.match(.tok_else)) {
            else_scope_idx = MultiScopeTable.createScope();
            const else_scope = &MultiScopeTable.table.items[else_scope_idx];
            parser.block(else_scope);
        }
        const if_symbol: IfSymbol = .{ .if_scope_idx = if_scope_idx, .else_scope_idx = else_scope_idx };
        const if_idx = IfTable.appendIf(if_symbol);
        const loc: LocInfo = .{ .start = if_token.loc.start, .end = if_token.loc.end, .line = if_token.loc.line };
        return parser.ast.addUnaryNode(.ast_if, if_idx, expr, loc);
    }

    pub fn reportError(parser: *Parser, loc: LocInfo, comptime str: []const u8, args: anytype, exit: bool) void {
        std.debug.print("{s}:{d}: ", .{ parser.source_name, loc.line + 1 });
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

    pub fn parse(parser: *Parser) void {
        while (parser.peek().type != .tok_eof) {
            switch (parser.peek().type) {
                .tok_var => {
                    //                    parser.ast_roots.append(parser.varStatement()) catch |err|{
                    //                        std.debug.print("Unable to append var statement ast node to root list: {}", .{err});
                    //                    };
                    unreachable;
                },
                .tok_print => {
                    //                    parser.ast_roots.append(parser.printStatement()) catch |err|{
                    //                        std.debug.print("Unable to append print statement ast node to root list: {}", .{err});
                    //                    };
                    unreachable;
                },
                .tok_fn => {
                    parser.ast_roots.append(parser.functionBlock()) catch |err| {
                        std.debug.print("Unable to append function block ast node to root list: {}", .{err});
                    };
                },
                else => {
                    unreachable;
                    //                    parser.ast_roots.append(parser.expressionStatement()) catch |err|{
                    //                        std.debug.print("Unable to append expression statement ast node to root list: {}", .{err});
                    //                    };
                },
            }
        }
    }

    fn typeTokenToSymbolType(token: Token) SymbolType {
        var symbol_type: SymbolType = undefined;
        switch (token.type) {
            .tok_int_type => symbol_type = .t_int,
            .tok_float_type => symbol_type = .t_float,
            .tok_bool_type => symbol_type = .t_bool,
            .tok_void_type => symbol_type = .t_void,
            else => unreachable,
        }
        return symbol_type;
    }
};
