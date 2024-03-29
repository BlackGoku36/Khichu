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

const nan_u32 = std.math.nan_u32;

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
        if (parser.match(.int)) {
            const int_lit = parser.peekPrev();
            return parser.ast.addLiteralNode(.int_literal, std.math.nan_u32, int_lit.loc);
        }
        if (parser.match(.float)) {
            const float_lit = parser.peekPrev();
            return parser.ast.addLiteralNode(.float_literal, std.math.nan_u32, float_lit.loc);
        }
        if (parser.match(.true) or parser.match(.false)) {
            const bool_lit = parser.peekPrev();
            return parser.ast.addLiteralNode(.bool_literal, std.math.nan_u32, bool_lit.loc);
        }
        if(parser.match(.identifier)){
            const ident = parser.peekPrev();
            return parser.ast.addLiteralNode(.identifier, std.math.nan_u32, ident.loc);
        }
        if (parser.match(.left_paren)) {
            const left_paren = parser.peekPrev();
            var expr: u32 = parser.expression();
            if (!parser.match(.right_paren)) parser.reportError(left_paren.loc, "Expected ')' after expression\n", .{}, true);
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
            return parser.ast.addUnaryNode(.negate, std.math.nan_u32, node, loc);
        }
        if (parser.match(.not)) {
            const not = parser.peekPrev();
            const node = parser.unary();
            const loc: LocInfo = .{
                .start = not.loc.start,
                .end = parser.getNode(node).loc.end,
                .line = not.loc.line,
            };
            return parser.ast.addUnaryNode(.bool_not, std.math.nan_u32, node, loc);
        }
        return parser.primary();
    }

    fn factor(parser: *Parser) u32 {
        var left = parser.unary();
        while (parser.match(.star) or parser.match(.slash)) {
            const op_token = parser.peekPrev();
            const op_type: Type = if (op_token.type == .star) .mult else .div;
            const right = parser.unary();
            left = parser.ast.addNode(op_type, std.math.nan_u32, left, right, op_token.loc);
        }
        return left;
    }

    fn term(parser: *Parser) u32 {
        var left = parser.factor();
        while (parser.match(.plus) or parser.match(.minus)) {
            const op_token = parser.peekPrev();
            const op_type: Type = if (op_token.type == .plus) .add else .sub;
            const right = parser.factor();
            left = parser.ast.addNode(op_type, std.math.nan_u32, left, right, op_token.loc);
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
            left = parser.ast.addNode(op_type, std.math.nan_u32, left, right, op_token.loc);
        }
        return left;
    }

    fn equality(parser: *Parser) u32 {
        var left = parser.comparision();
        while (parser.match(.equal_equal) or parser.match(.not_equal)) {
            const op_token = parser.peekPrev();
            const op_type: Type = if (op_token.type == .equal_equal) .equal_equal else .not_equal;
            const right = parser.comparision();
            left = parser.ast.addNode(op_type, std.math.nan_u32, left, right, op_token.loc);
        }
        return left;
    }

    fn logical(parser: *Parser) u32 {
        var left = parser.equality();
        while (parser.match(.amp_amp) or parser.match(.pipe_pipe)) {
            const op_token = parser.peekPrev();
            const op_type: Type = if (op_token.type == .amp_amp) .bool_and else .bool_or;
            const right = parser.equality();
            left = parser.ast.addNode(op_type, std.math.nan_u32, left, right, op_token.loc);
        }
        return left;
    }

    fn assignment(parser: *Parser) u32 {
        const ident_idx = parser.logical();
        const ident_node = parser.ast.nodes.items[ident_idx];
        if(parser.match(.equal)){
            if(ident_node.type != .identifier){
                parser.reportError(ident_node.loc, "Expected 'identifier' before '=', found '{s}'.\n", .{ ident_node.type.str()}, true);
            }
            const expr_node = parser.assignment();
            const loc: LocInfo = .{
                .start = ident_node.loc.start,
                .end = parser.peekPrev().loc.end,
                .line = ident_node.loc.line
            };
            return parser.ast.addNode(.assign_stmt, std.math.nan_u32, ident_idx, expr_node, loc);
        }
        return ident_idx;
    }

    fn expression(parser: *Parser) u32 {
        return parser.assignment();
    }

    fn expressionStatement(parser: *Parser) u32 {
        const expr = parser.expression();
        if(!parser.match(.semi_colon)){
            parser.reportError(parser.peekPrev().loc, "Expected ';' after 'expression', found '{s}'.\n", .{ parser.peekPrev().type.str()}, true);
        }
        return expr;
    }

    //TODO: check if this can be cleaned up
    fn varStatement(parser: *Parser) u32 {
        const var_token = parser.consume(); //Consume 'var' token
        if(!parser.match(.identifier)){
            parser.reportError(var_token.loc, "Expected identifier after 'var', found '{s}'.\n", .{ parser.peekPrev().type.str()}, true);
        }

        const ident = parser.peekPrev();

        const var_exist = SymbolTable.exists(parser.source[ident.loc.start..ident.loc.end]);
        if(var_exist){
            parser.reportError(ident.loc, "Variable named '{s}' already exists.\n", .{parser.source[ident.loc.start..ident.loc.end]}, true);
        }

        if (!parser.match(.colon)) {
            parser.reportError(parser.peekPrev().loc, "Expected ':' after 'identifier' and before 'type', found '{s}'.\n", .{ parser.peekPrev().type.str()}, true);
        }

        const type_token = parser.consume();
        if(type_token.type != .int_type and type_token.type != .float_type and type_token.type != .bool_type){
            parser.reportError(type_token.loc, "Expected 'type' after ':' and before '=', found '{s}'.\n", .{ type_token.type.str()}, true);
        }

        if(!parser.match(.equal)){
            parser.reportError(parser.peekPrev().loc, "Expected '=' after 'type' and before 'expression', found '{s}'.\n", .{ parser.peekPrev().type.str()}, true);
        }

        const expr_node = parser.expressionStatement();

        var symbol_type:SymbolType = undefined;
        switch(type_token.type){
            .int_type => symbol_type = .t_int,
            .float_type => symbol_type = .t_float,
            .bool_type => symbol_type = .t_bool,
            else => unreachable,
        }

        const symbol_idx = SymbolTable.appendVar(.{
            .name = parser.source[ident.loc.start..ident.loc.end],
            .type = symbol_type,
            .expr_node = expr_node
        });

        const loc: LocInfo = .{.start = var_token.loc.start, .end = parser.peekPrev().loc.end, .line = var_token.loc.line};
        return parser.ast.addLiteralNode(.var_stmt, symbol_idx, loc);
    }

    fn printStatement(parser: *Parser) u32 {
        const print_token = parser.consume();
        if(!parser.match(.left_paren)){
            parser.reportError(parser.peekPrev().loc, "Expected '(' after 'print', found '{s}'.\n", .{ parser.peekPrev().type.str()}, true);
        }
        const expr_node = parser.expression();
        if(!parser.match(.right_paren)){
            parser.reportError(parser.peekPrev().loc, "Expected ')' after 'expression', found '{s}'.\n", .{ parser.peekPrev().type.str()}, true);
        }
        if(!parser.match(.semi_colon)){
            parser.reportError(parser.peekPrev().loc, "Expected ';' at end of statement, found '{s}'.\n", .{ parser.peekPrev().type.str()}, true);
        }
        const loc: LocInfo = .{.start = print_token.loc.start, .end = parser.peekPrev().loc.end, .line = print_token.loc.line};
        return parser.ast.addUnaryNode(.print_stmt, std.math.nan_u32, expr_node, loc);
    }

    fn reportError(parser: *Parser, loc: LocInfo, comptime str: []const u8, args: anytype, exit: bool) void {
        std.debug.print("{s}:{d}: ", .{ parser.source_name, loc.line + 1});
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

    pub fn analyse_type_semantic(parser: *Parser, curr_node: u32) void {
    	var node = &parser.ast.nodes.items[curr_node];
		var left_exist = node.left != nan_u32;
		var right_exist = node.right != nan_u32;

    	if (left_exist) {
   		     parser.analyse_type_semantic(node.left);
    	}
    	if (right_exist) {
   		     parser.analyse_type_semantic(node.right);
    	}

     	// TODO: I forgot why I keep checking left/right exist for operations?
     	switch(node.type){
      		.add, .sub, .mult, .div => {
        		if(left_exist and right_exist){
          			var left_type: SymbolType = undefined;
          			var right_type: SymbolType = undefined;
             		const left_node: Node = parser.ast.nodes.items[node.left];
             		const right_node: Node = parser.ast.nodes.items[node.right];
               		switch(left_node.type){
                 		.identifier => {
                 			const name: []u8 = parser.source[left_node.loc.start..left_node.loc.end];
                			if(SymbolTable.findByName(name)) | sym |{
                 				left_type = sym.type;
                 			}else{
                   				unreachable;
                   			}
                   		},
                     	.int_literal => left_type = .t_int,
                      	.float_literal => left_type = .t_float,
                       	.bool_literal => left_type = .t_bool,
                       	.add, .sub, .mult, .div, .negate => {
                        	left_type = ExprTypeTable.table.items[left_node.idx].type;
                        },
                        else => {unreachable;},
                 	}
                  	switch(right_node.type){
                  		.identifier => {
                  			const name: []u8 = parser.source[right_node.loc.start..right_node.loc.end];
                 			if(SymbolTable.findByName(name)) | sym |{
                  				right_type = sym.type;
                  			}else{
                     			unreachable;
                        	}
                       	},
                     	.int_literal => right_type = .t_int,
                      	.float_literal => right_type = .t_float,
                       	.bool_literal => right_type = .t_bool,
                        .add, .sub, .mult, .div, .negate => {
                         	right_type = ExprTypeTable.table.items[right_node.idx].type;
                        },
                        else =>{unreachable;},
                  	}
                  	if(left_type != right_type){
                   		parser.reportError(node.loc, "Types miss-match between '{s}' and '{s}'\n", .{ left_type.str(), right_type.str() }, false);
                   		parser.reportError(left_node.loc, "Type '{s}' declared here:\n", .{left_type.str()}, false);
                   		parser.reportError(right_node.loc, "Type '{s}' declared here:\n", .{right_type.str()}, true);
                   	}
                    node.idx = ExprTypeTable.appendExprType(left_type);
          		}else if(left_exist and !right_exist){
            		@panic("TODO!");
            	}else if(right_exist and !left_exist){
             		@panic("TODO!");
             	}
        	},
         	.negate => {
          		// TODO: Remove this code duplication
          		if(left_exist){
         			var left_type: SymbolType = undefined;
            		const left_node: Node = parser.ast.nodes.items[node.left];
              		switch(left_node.type){
                		.identifier => {
                			const name: []u8 = parser.source[left_node.loc.start..left_node.loc.end];
                			if(SymbolTable.findByName(name)) | sym |{
                				left_type = sym.type;
                			}else{
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
         	else => {}
      	}
    }

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

    pub fn parse(parser: *Parser) void {
        while(parser.peek().type != .eof){
            switch (parser.peek().type) {
                .@"var" => {
                    parser.ast_roots.append(parser.varStatement()) catch |err|{
                        std.debug.print("Unable to append var statement ast node to root list: {}", .{err});
                    };
                },
                .print => {
                    parser.ast_roots.append(parser.printStatement()) catch |err|{
                        std.debug.print("Unable to append print statement ast node to root list: {}", .{err});
                    };
                },
                else => {
                    parser.ast_roots.append(parser.expressionStatement()) catch |err|{
                        std.debug.print("Unable to append expression statement ast node to root list: {}", .{err});
                    };
                }
            }
        }
    }

    pub fn analyze(parser: *Parser) void {
        // Analyze
        for (parser.ast_roots.items) |root_idx| {
            const ast_node = parser.ast.nodes.items[root_idx];
            switch(ast_node.type){
                .var_stmt => {
                    const symbol_idx = ast_node.idx;
                    const symbol_entry = SymbolTable.varTable.get(symbol_idx);
//                    parser.analyse_bool(symbol_entry.expr_node);
                    _ = parser.analyse_chain_type(symbol_entry.expr_node);
                    parser.analyse_type_semantic(symbol_entry.expr_node);
                },
                .print_stmt => {
                    const left_idx = ast_node.left;
//                    parser.analyse_bool(left_idx);
                    _ = parser.analyse_chain_type(left_idx);
                    parser.analyse_type_semantic(left_idx);
                },
                .assign_stmt => {
                    const right_idx = ast_node.right;
//                    parser.analyse_bool(right_idx);
                    _ = parser.analyse_chain_type(right_idx);
                    parser.analyse_type_semantic(right_idx);
                },
                else => {}
            }
        }
    }
};
