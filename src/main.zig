const std = @import("std");
const Tokenizer = @import("tokenizer.zig").Tokenizer;
const Parser = @import("parser.zig").Parser;
const tables = @import("tables.zig");
const SymbolTable = tables.SymbolTable;
const ExprTypeTable = tables.ExprTypeTable;
const FnTable = tables.FnTable;
const FnCallTable = tables.FnCallTable;
const IfTable = tables.IfTable;
const MultiScopeTable = tables.MultiScopeTable;
const analyzer = @import("analyzer.zig");

const wasm_codegen = @import("wasm/codegen.zig");

var gp = std.heap.GeneralPurposeAllocator(.{}){};

pub fn main() !void {
    var allocator = gp.allocator();
    defer _ = gp.deinit();

    const source_name = "demo.k";

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

    SymbolTable.createTables(allocator);
    defer SymbolTable.destroyTable();

    ExprTypeTable.createTable(allocator);
    defer ExprTypeTable.destroyTable();

    FnTable.createTable(allocator);
    defer FnTable.destroyTable();

    FnCallTable.createTable(allocator);
    defer FnCallTable.destroyTable();

    IfTable.createTable(allocator);
    defer IfTable.destroyTable();

    MultiScopeTable.createTable(allocator);
    defer MultiScopeTable.destroyTable();

    var parser = Parser.init(allocator, tokenizer);
    defer parser.deinit();

    parser.parse();
    analyzer.analyze(&parser);

    std.debug.print("\n------ AST ------\n", .{});
    parser.ast.printAst(&parser.ast_roots);

    std.debug.print("\n------ VAR SYMBOL TABLE ------\n", .{});
    SymbolTable.printVar();

    std.debug.print("\n------ EXPR TYPE TABLE -------\n", .{});
    ExprTypeTable.printExprTypes();

    std.debug.print("\n------ FN TABLE -------\n", .{});
    FnTable.printFunctions(source, parser.ast);

    std.debug.print("\n------ FN CALL TABLE -------\n", .{});
    FnCallTable.printFunctions(source, &parser.ast);

    std.debug.print("\n------ IFs TABLE -------\n", .{});
    IfTable.printIfs();

    std.debug.print("\n-----------------------------\n", .{});

    var out_file = try std.fs.cwd().createFile("out.wasm", .{});
    defer out_file.close();

    try wasm_codegen.outputFile(out_file, &parser, source, allocator);
}
