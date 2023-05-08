const std = @import("std");
const Tokenizer = @import("tokenizer.zig").Tokenizer;
const Parser = @import("parser.zig").Parser;
const ByteCodePool = @import("bytecode.zig").ByteCodePool;
const codegen = @import("codegen.zig");
const VM = @import("vm.zig").VM;

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

    var parser = Parser.init(allocator, tokenizer);
    defer parser.deinit();

    const node = parser.parse();
    std.debug.print("\n------ AST ------\n", .{});
    parser.ast.print(node, 0, 0);

    var bytecode_pool = ByteCodePool.init(allocator);
    defer bytecode_pool.deinit();

    codegen.generateCode(&parser.ast, node, source, &bytecode_pool);
    std.debug.print("\n------ BYTECODE ------\n", .{});
    bytecode_pool.print();

    var vm = VM.init(allocator, bytecode_pool);
    defer vm.deinit();
    std.debug.print("\n------ VM ------\n", .{});
    try vm.run();
}
