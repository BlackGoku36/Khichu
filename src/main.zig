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
    std.debug.print("\n", .{});

    SymbolTable.createTables(allocator);
    ExprTypeTable.createTable(allocator);
    FnTable.createTable(allocator);
    FnCallTable.createTable(allocator);
    IfTable.createTable(allocator);
    MultiScopeTable.createTable(allocator);

    var parser = Parser.init(allocator, tokenizer);
    defer parser.deinit();

    parser.parse();
    std.debug.print("\n------ AST ------\n", .{});
    for (parser.ast_roots.items) |roots| {
        parser.ast.print(roots, 0, 0);
    }
    //    for (FnTable.table.items) |fn_block|{
    //        for(fn_block.body_nodes_start..fn_block.body_nodes_end) |node_i| {
    //            //const fn_body_node = parser.ast.nodes.items[node_i];
    //            parser.ast.print(@intCast(node_i), 0, 0);
    //        }
    //    }
    analyzer.analyze(&parser);
    //    std.debug.print("\n------ NEW AST ------\n", .{});
    //    for (parser.ast_roots.items) |roots| {
    //        parser.ast.print(roots, 0, 0);
    //    }

    std.debug.print("\n------ SYMBOL TABLE (VAR)------\n", .{});
    SymbolTable.printVar();

    std.debug.print("\n------ EXPR TYPE TABLE -------\n", .{});
    ExprTypeTable.printExprTypes();

    std.debug.print("\n------ FN TABLE -------\n", .{});
    FnTable.printFunctions(source, parser.ast);

    std.debug.print("\n------ FN CALL TABLE -------\n", .{});
    FnCallTable.printFunctions(source, parser.ast);

    std.debug.print("\n------ IFs TABLE -------\n", .{});
    IfTable.printIfs();
    
    std.debug.print("\n-----------------------------\n", .{});


    var out_file = try std.fs.cwd().createFile("out.wasm", .{});
    defer out_file.close();

    try wasm_codegen.outputFile(out_file, &parser, source, allocator);

    //    var bytecode_pool = ByteCodePool.init(allocator);
    //    defer bytecode_pool.deinit();
    //
    //    for (parser.ast_roots.items) |roots| {
    //        codegen.generateCode(&parser.ast, roots, source, &bytecode_pool);
    //    }
    //
    //    std.debug.print("\n------ BYTECODE ------\n", .{});
    //    bytecode_pool.print();
    //
    ExprTypeTable.destroyTable();
    SymbolTable.destroyTables();
    FnTable.destroyTable();
    FnCallTable.destroyTable();
    IfTable.destroyTable();
    MultiScopeTable.destroyTable();
    //
    //    var vm = VM.init(allocator, bytecode_pool);
    //    defer vm.deinit();
    //    std.debug.print("\n------ VM ------\n", .{});
    //    try vm.run();
    //
    //    std.debug.print("\n------ GLOBAL VAR TABLE ------\n", .{});
    //    bytecode_pool.global_var_tables.print();
}
