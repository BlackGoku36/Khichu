const std = @import("std");

pub const LocInfo = struct {
    start: u32,
    end: u32,
    line: u32,
};

pub const TokenType = enum {
    tok_int,
    tok_float,
    tok_plus,
    tok_minus,
    tok_star,
    tok_slash,
    tok_not,
    tok_amp,
    tok_amp_amp,
    tok_pipe,
    tok_pipe_pipe,
    tok_equal,
    tok_equal_equal,
    tok_not_equal,
    tok_greater_equal,
    tok_lesser_equal,
    tok_greater,
    tok_lesser,
    tok_left_paren,
    tok_right_paren,
    tok_left_brace,
    tok_right_brace,
    tok_colon,
    tok_semi_colon,
    tok_true,
    tok_false,
    tok_bool,
    tok_identifier,
    tok_var,
    tok_if,
    tok_else,
    tok_print,
    tok_int_type,
    tok_float_type,
    tok_bool_type,
    tok_fn,
    tok_void_type,
    tok_return,
    tok_comma,
    tok_eof,

    pub fn str(token_type: TokenType) []const u8 {
        switch (token_type) {
            .tok_int => return "int",
            .tok_float => return "float",
            .tok_plus => return "plus",
            .tok_minus => return "minus",
            .tok_star => return "star",
            .tok_slash => return "slash",
            .tok_not => return "not",
            .tok_amp => return "and",
            .tok_amp_amp => return "amp_amp",
            .tok_pipe => return "pipe",
            .tok_pipe_pipe => return "pipe_pipe",
            .tok_equal => return "equal",
            .tok_equal_equal => return "equal_equal",
            .tok_not_equal => return "not_equal",
            .tok_greater_equal => return "greater_equal",
            .tok_lesser_equal => return "lesser_equal",
            .tok_greater => return "greater",
            .tok_lesser => return "lesser",
            .tok_left_paren => return "left_paren",
            .tok_right_paren => return "right_paren",
            .tok_left_brace => return "left_brace",
            .tok_right_brace => return "right_brace",
            .tok_colon => return "colon",
            .tok_semi_colon => return "semi_colon",
            .tok_true => return "true",
            .tok_false => return "false",
            .tok_bool => return "bool",
            .tok_identifier => return "identifier",
            .tok_var => return "var",
            .tok_if => return "if",
            .tok_else => return "else",
            .tok_print => return "print",
            .tok_int_type => return "int_type",
            .tok_float_type => return "float_type",
            .tok_bool_type => return "bool_type",
            .tok_fn => return "fn",
            .tok_void_type => return "void_type",
            .tok_return => return "return",
            .tok_comma => return "comma",
            .tok_eof => return "eof",
        }
    }

    pub fn reservedStr(token_type: TokenType) []const u8 {
        switch (token_type) {
            .tok_var => return "var",
            .tok_if => return "if",
            .tok_else => return "else",
            .tok_print => return "print",
            .tok_int_type => return "int",
            .tok_float_type => return "float",
            .tok_bool_type => return "bool",
            .tok_true => return "true",
            .tok_false => return "false",
            .tok_fn => return "fn",
            .tok_void_type => return "void",
            .tok_return => return "return",
            else => {
                return "";
            },
        }
    }
};

pub const Token = struct {
    type: TokenType,
    loc: LocInfo,
};

pub const Tokenizer = struct {
    source: []u8,
    source_name: []const u8,
    start: u32 = 0,
    current: u32 = 0,
    line: u32 = 0,
    pool: std.ArrayList(Token),

    pub fn init(allocator: std.mem.Allocator, source: []u8, source_name: []const u8) Tokenizer {
        const tokenizer: Tokenizer = .{
            .source = source,
            .source_name = source_name,
            .pool = std.ArrayList(Token).init(allocator),
        };
        return tokenizer;
    }

    fn peek(tokenizer: *Tokenizer) u8 {
        if (tokenizer.current >= tokenizer.source.len) return 0;
        return tokenizer.source[tokenizer.current];
    }

    fn peek_next(tokenizer: *Tokenizer) u8 {
        if (tokenizer.current >= tokenizer.source.len) return 0;
        return tokenizer.source[tokenizer.current + 1];
    }

    fn consume(tokenizer: *Tokenizer) u8 {
        const char = tokenizer.peek();
        tokenizer.current += 1;
        return char;
    }

    fn match(tokenizer: *Tokenizer, char: u8) bool {
        if (tokenizer.peek() != char) return false;
        _ = tokenizer.consume();
        return true;
    }

    fn add_token(tokenizer: *Tokenizer, token_type: TokenType) void {
        tokenizer.pool.append(.{ .type = token_type, .loc = .{ .start = tokenizer.start, .end = tokenizer.current, .line = tokenizer.line } }) catch |err| {
            std.debug.print("Error while adding token: {any}\n", .{err});
        };
    }

    fn parseIdentifier(tokenizer: *Tokenizer) TokenType {
        const reserved = [_]TokenType{ .tok_true, .tok_false, .tok_var, .tok_print, .tok_int_type, .tok_float_type, .tok_bool_type, .tok_fn, .tok_void_type, .tok_return, .tok_if, .tok_else };

        var out_token_type: TokenType = .tok_identifier;

        while (tokenizer.current < tokenizer.source.len and std.ascii.isAlphanumeric(tokenizer.peek())) _ = tokenizer.consume();

        for (reserved, 0..) |token_type, i| {
            if (std.mem.eql(u8, tokenizer.source[tokenizer.start..tokenizer.current], token_type.reservedStr())) {
                out_token_type = reserved[i];
                break;
            }
        }

        return out_token_type;
    }

    fn parseNumber(tokenizer: *Tokenizer) bool {
        var is_float = false;
        while (tokenizer.current < tokenizer.source.len and std.ascii.isDigit(tokenizer.peek())) _ = tokenizer.consume();
        if (tokenizer.peek() == '.' and std.ascii.isDigit(tokenizer.peek_next())) {
            _ = tokenizer.consume();
            is_float = true;
            while (tokenizer.current < tokenizer.source.len and std.ascii.isDigit(tokenizer.peek())) _ = tokenizer.consume();
        }
        return is_float;
    }

    pub fn tokenize(tokenizer: *Tokenizer) void {
        while (tokenizer.current < tokenizer.source.len) {
            tokenizer.start = tokenizer.current;
            const char: u8 = tokenizer.consume();
            switch (char) {
                '+' => {
                    tokenizer.add_token(.tok_plus);
                },
                '-' => {
                    tokenizer.add_token(.tok_minus);
                },
                '*' => {
                    tokenizer.add_token(.tok_star);
                },
                '/' => {
                    if (tokenizer.match('/')) {
                        while (tokenizer.current < tokenizer.source.len and tokenizer.consume() != '\n') {}
                        tokenizer.line += 1;
                    } else {
                        tokenizer.add_token(.tok_slash);
                    }
                },
                '=' => {
                    const token_type: TokenType = if (tokenizer.match('=')) .tok_equal_equal else .tok_equal;
                    tokenizer.add_token(token_type);
                },
                '!' => {
                    const token_type: TokenType = if (tokenizer.match('=')) .tok_not_equal else .tok_not;
                    tokenizer.add_token(token_type);
                },
                '&' => {
                    const token_type: TokenType = if (tokenizer.match('&')) .tok_amp_amp else .tok_amp;
                    tokenizer.add_token(token_type);
                },
                '|' => {
                    const token_type: TokenType = if (tokenizer.match('|')) .tok_pipe_pipe else .tok_pipe;
                    tokenizer.add_token(token_type);
                },
                '>' => {
                    const token_type: TokenType = if (tokenizer.match('=')) .tok_greater_equal else .tok_greater;
                    tokenizer.add_token(token_type);
                },
                '<' => {
                    const token_type: TokenType = if (tokenizer.match('=')) .tok_lesser_equal else .tok_lesser;
                    tokenizer.add_token(token_type);
                },
                '(' => tokenizer.add_token(.tok_left_paren),
                ')' => tokenizer.add_token(.tok_right_paren),
                '{' => tokenizer.add_token(.tok_left_brace),
                '}' => tokenizer.add_token(.tok_right_brace),
                ':' => tokenizer.add_token(.tok_colon),
                ';' => tokenizer.add_token(.tok_semi_colon),
                ',' => tokenizer.add_token(.tok_comma),
                ' ' => {},
                '\r' => {},
                '\t' => {},
                '\n' => tokenizer.line += 1,
                else => {
                    if (std.ascii.isDigit(char)) {
                        const is_float = tokenizer.parseNumber();
                        tokenizer.add_token(if (is_float) .tok_float else .tok_int);
                    } else if (std.ascii.isAlphabetic(char)) {
                        const token_type = tokenizer.parseIdentifier();
                        tokenizer.add_token(token_type);
                    } else {
                        tokenizer.reportError("Unexpected char found!", true);
                    }
                },
            }
        }
        tokenizer.add_token(.tok_eof);
    }

    fn reportError(tokenizer: *Tokenizer, err: []const u8, exit: bool) void {
        std.debug.print("Error at line {d}: {s}\n", .{ tokenizer.line, err });

        var error_line_offset: u32 = 0;
        var line_counter: u32 = 0;
        // Get offset to the line containing error.
        while (error_line_offset < tokenizer.source.len) : (error_line_offset += 1) {
            if (line_counter == tokenizer.line) break;
            if (tokenizer.source[error_line_offset] == '\n') line_counter += 1;
        }
        // Print the line
        var i: u32 = error_line_offset;
        while (i < tokenizer.source.len and tokenizer.source[i] != '\n') : (i += 1) {
            std.debug.print("{c}", .{tokenizer.source[i]});
        }
        std.debug.print("\n", .{});
        // Print the fancy pointer
        for (error_line_offset..i) |j| {
            if (j == tokenizer.start) std.debug.print("^", .{}) else std.debug.print("-", .{});
        }
        std.debug.print("\n", .{});

        std.process.exit(@intFromBool(exit));
    }

    pub fn print(tokenizer: *Tokenizer) void {
        for (0..tokenizer.pool.items.len) |i| {
            const token = tokenizer.pool.items[i];
            std.debug.print("Token, type: {s}, src: {s}\n", .{ token.type.str(), tokenizer.source[token.loc.start..token.loc.end] });
        }
    }

    pub fn deinit(tokenizer: *Tokenizer) void {
        tokenizer.pool.deinit();
    }
};
