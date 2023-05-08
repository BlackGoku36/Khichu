const std = @import("std");

pub const LocInfo = struct {
    start: u32,
    end: u32,
    line: u32,
};

pub const TokenType = enum {
    int,
    float,
    plus,
    minus,
    star,
    slash,
    not,
    amp,
    amp_amp,
    pipe,
    pipe_pipe,
    equal,
    equal_equal,
    not_equal,
    greater_equal,
    lesser_equal,
    greater,
    lesser,
    left_paren,
    right_paren,
    true,
    false,
    bool,
    identifier,
    eof,

    pub fn str(token_type: TokenType) []const u8 {
        switch (token_type) {
            .int => return "int",
            .float => return "float",
            .plus => return "plus",
            .minus => return "minus",
            .star => return "star",
            .slash => return "slash",
            .not => return "not",
            .amp => return "and",
            .amp_amp => return "amp_amp",
            .pipe => return "pipe",
            .pipe_pipe => return "pipe_pipe",
            .equal => return "equal",
            .equal_equal => return "equal_equal",
            .not_equal => return "not_equal",
            .greater_equal => return "greater_equal",
            .lesser_equal => return "lesser_equal",
            .greater => return "greater",
            .lesser => return "lesser",
            .left_paren => return "left_paren",
            .right_paren => return "right_paren",
            .true => return "true",
            .false => return "false",
            .bool => return "bool",
            .identifier => return "identifier",
            .eof => return "eof",
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
        var tokenizer: Tokenizer = .{
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
        const identifiers = [_]TokenType{ .true, .false };

        var out_token_type: TokenType = .identifier;

        while (tokenizer.current < tokenizer.source.len and std.ascii.isAlphanumeric(tokenizer.peek())) _ = tokenizer.consume();

        for (identifiers, 0..) |token_type, i| {
            if (std.mem.eql(u8, tokenizer.source[tokenizer.start..tokenizer.current], token_type.str())) {
                out_token_type = identifiers[i];
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
            var char: u8 = tokenizer.consume();
            switch (char) {
                '+' => {
                    tokenizer.add_token(.plus);
                },
                '-' => {
                    tokenizer.add_token(.minus);
                },
                '*' => {
                    tokenizer.add_token(.star);
                },
                '/' => {
                    tokenizer.add_token(.slash);
                },
                '=' => {
                    const token_type: TokenType = if (tokenizer.match('=')) .equal_equal else .equal;
                    tokenizer.add_token(token_type);
                },
                '!' => {
                    const token_type: TokenType = if (tokenizer.match('=')) .not_equal else .not;
                    tokenizer.add_token(token_type);
                },
                '&' => {
                    const token_type: TokenType = if (tokenizer.match('&')) .amp_amp else .amp;
                    tokenizer.add_token(token_type);
                },
                '|' => {
                    const token_type: TokenType = if (tokenizer.match('|')) .pipe_pipe else .pipe;
                    tokenizer.add_token(token_type);
                },
                '>' => {
                    const token_type: TokenType = if (tokenizer.match('=')) .greater_equal else .greater;
                    tokenizer.add_token(token_type);
                },
                '<' => {
                    const token_type: TokenType = if (tokenizer.match('=')) .lesser_equal else .lesser;
                    tokenizer.add_token(token_type);
                },
                '(' => tokenizer.add_token(.left_paren),
                ')' => tokenizer.add_token(.right_paren),
                ' ' => {},
                '\r' => {},
                '\t' => {},
                '\n' => tokenizer.line += 1,
                else => {
                    if (std.ascii.isDigit(char)) {
                        const is_float = tokenizer.parseNumber();
                        tokenizer.add_token(if (is_float) .float else .int);
                    } else if (std.ascii.isAlphabetic(char)) {
                        const token_type = tokenizer.parseIdentifier();
                        tokenizer.add_token(token_type);
                    } else {
                        tokenizer.reportError("Unexpected char found!", true);
                    }
                },
            }
        }
        tokenizer.add_token(.eof);
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

        std.process.exit(@boolToInt(exit));
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
