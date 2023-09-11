const std = @import("std");
const Tokenizer = @import("tokenizer.zig").Tokenizer;
const Parser = @import("parser.zig").Parser;
const ByteCodePool = @import("bytecode.zig").ByteCodePool;
const codegen = @import("codegen.zig");
const VM = @import("vm.zig").VM;
const Symbol = @import("symbol.zig").Symbol;

var gp = std.heap.GeneralPurposeAllocator(.{}){};

pub fn main() !void {
    var allocator = gp.allocator();
    defer _ = gp.deinit();

    var source_name = "test.ul";

    var file = try std.fs.cwd().openFile(source_name, .{});
    defer file.close();

    const buffer_size = 10000;
    const source = try file.readToEndAlloc(allocator, buffer_size);
    defer allocator.free(source);

    var tokenizer = Tokenizer.init(allocator, source, source_name);
    defer tokenizer.deinit();

    tokenizer.tokenize();
    std.debug.print("\n------ TOKENS ------\n", .{});
    tokenizer.print();

    Symbol.createTables(allocator);

    var parser = Parser.init(allocator, tokenizer);
    defer parser.deinit();

    parser.parse();
    std.debug.print("\n------ AST ------\n", .{});
    for (parser.ast_roots.items) |roots| {
        parser.ast.print(roots, 0, 0);
    }

    std.debug.print("\n------ SYMBOL TABLE (VAR)------\n", .{});
    Symbol.printVar();

    var bytecode_pool = ByteCodePool.init(allocator);
    defer bytecode_pool.deinit();

    for (parser.ast_roots.items) |roots| {
        codegen.generateCode(&parser.ast, roots, source, &bytecode_pool);
        std.debug.print("\n------ BYTECODE ------\n", .{});
        bytecode_pool.print();
    }

    Symbol.destroyTables();

    var vm = VM.init(allocator, bytecode_pool);
    defer vm.deinit();
    std.debug.print("\n------ VM ------\n", .{});
    try vm.run();

    std.debug.print("\n------ GLOBAL VAR TABLE ------\n", .{});
    bytecode_pool.global_var_tables.print();
}
