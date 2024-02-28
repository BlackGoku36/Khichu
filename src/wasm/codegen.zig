const std = @import("std");
const Ast = @import("../ast.zig").Ast;
//const ByteCodePool = @import("bytecode.zig").ByteCodePool;
//const ByteCode = @import("bytecode.zig").ByteCode;
//const Value = @import("bytecode.zig").Value;
const SymbolTable = @import("../tables.zig").SymbolTable;
const Parser = @import("../parser.zig").Parser;

const wasm = @import("wasm.zig");
const Module = wasm.Module;
const SectionType = wasm.SectionType;
const FunctionType = wasm.FunctionType;
//const ValueType = wasm.ValueType;
const FunctionSection = wasm.FunctionSection;
const Code = wasm.Code;
const Local = wasm.Local;
const Inst = wasm.Inst;
const ValueType = wasm.ValueType;
const OpCode = wasm.OpCode;

pub const VariableValueType = enum { int, float, boolean };
pub const VariableValue = union(VariableValueType) {
    int: i32,
    float: f32,
    boolean: bool,
};
pub const Variable = struct{
    identifier: []u8,
    value: VariableValue
};

pub const VarTable = struct{
    variables: std.ArrayList(Variable),

    pub fn init(allocator: std.mem.Allocator) VarTable {
        return .{
            .variables = std.ArrayList(Variable).init(allocator),
        };
    }

 //   pub fn print(gv_table: *GlobalVarTables) void {
 //       var map_iter = gv_table.values.iterator();
 //       while(map_iter.next()) |entry|{
 //           std.debug.print("key: {s}, ", .{entry.key_ptr.*});
 //           switch (entry.value_ptr.*) {
 //               .int => |val| std.debug.print("value: {d}\n", .{val}),
 //               .float => |val| std.debug.print("value: {d}\n", .{val}),
 //               .boolean => |val| std.debug.print("value: {any}\n", .{val}),
 //           }
 //       }
 //   }

    pub fn add(gv_table: *VarTable, identifier: []u8, value: VariableValue) !usize {
        try gv_table.variables.append(.{.identifier = identifier, .value = value});
        return gv_table.variables.items.len - 1;
    }

    pub fn get(gv_table: *VarTable, index: u32) Variable {
        return gv_table.variables[index];
    }

    pub fn getByName(gv_table: *VarTable, identifier: []u8) usize {
        for (gv_table.variables.items, 0..) |variable, i| {
            if(std.mem.eql(u8, variable.identifier, identifier)){
                return i;
            }
        }
        unreachable;
        //return gv_table.variables[index];
    }

    pub fn deinit(gv_table: *VarTable) void {
        gv_table.variables.deinit();
    }
};

pub fn outputFile(file: std.fs.File, parser: *Parser, source: []u8, allocator: std.mem.Allocator) !void {
    const module: Module = .{};

    var magic: [4]u8 = .{};
    std.mem.writeInt(u32, &magic, module.magic, .Big);
    var version: [4]u8 = .{};
    std.mem.writeInt(u32, &version, module.version, .Big);
    _ = try file.write(&magic);
    _ = try file.write(&version);

    var sectionType: SectionType = .{
        .size = 0,
        .func_type = std.ArrayList(FunctionType).init(allocator)
    };
    defer sectionType.func_type.deinit();
    try sectionType.func_type.append(.{
       .params = std.ArrayList(u8).init(allocator),
       .results = std.ArrayList(u8).init(allocator)
    });
    try sectionType.func_type.append(.{
       .params = std.ArrayList(u8).init(allocator),
       .results = std.ArrayList(u8).init(allocator)
    });
    defer {
        for(sectionType.func_type.items) |sec| {
            sec.params.deinit();
            sec.results.deinit();
        }
    }
    //try sectionType.func_type.items[0].results.append(0x7F);
    try sectionType.func_type.items[1].params.append(0x7F);

    var header_bytes: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer header_bytes.deinit();

    var body_bytes: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer body_bytes.deinit();

    try body_bytes.append(@intCast(sectionType.func_type.items.len));

    for(sectionType.func_type.items) |fns| {
        try body_bytes.append(fns.id);
        try body_bytes.append(@intCast(fns.params.items.len));
        for(fns.params.items) |param| {
            try body_bytes.append(param);
        }
        try body_bytes.append(@intCast(fns.results.items.len));
        for(fns.results.items) |result| {
            try body_bytes.append(result);
        }
    }

    try header_bytes.append(sectionType.id);
    try header_bytes.append(@intCast(body_bytes.items.len));

    _ = try file.write(header_bytes.items);
    _ = try file.write(body_bytes.items);

    _ = try file.write(&[_]u8{0x02, 0x0D, 0x01, 0x03, 0x73, 0x74, 0x64, 0x05, 0x70, 0x72, 0x69, 0x6E, 0x74, 0x00, 0x01});

    var functionSection: FunctionSection = .{
        .size = 0,
        .types = std.ArrayList(u32).init(allocator),
    };
    defer functionSection.types.deinit();
    try functionSection.types.append(0);

    var func_sec_header_bytes: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer func_sec_header_bytes.deinit();
    var func_sec_body_bytes: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer func_sec_body_bytes.deinit();

    try func_sec_body_bytes.append(@intCast(functionSection.types.items.len));
    for(functionSection.types.items) |type_idx|{
        try func_sec_body_bytes.append(@intCast(type_idx));
    }

    try func_sec_header_bytes.append(functionSection.id);
    try func_sec_header_bytes.append(@intCast(func_sec_body_bytes.items.len));

    _ = try file.write(func_sec_header_bytes.items);
    _ = try file.write(func_sec_body_bytes.items);

    // export func hard coded
    //_ = try file.write(&[_]u8{0x07,0x08,0x01,0x04,0x6D,0x61,0x69,0x6E,0x00,0x01});
    // hard code start section
    _ = try file.write(&[_]u8{0x08,0x01,0x01});

    var code = try generateWASM(parser, source, allocator);
    defer {
        code.locals.deinit();
        code.instructions.deinit();
    }

    var section_code_header_byte: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer section_code_header_byte.deinit();
    var section_code_body_byte: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer section_code_body_byte.deinit();
    var function_code_body_byte: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer function_code_body_byte.deinit();

    try function_code_body_byte.append(@intCast(code.locals.items.len));
    for(code.locals.items) |local| {
        try function_code_body_byte.append(@intCast(local.locals));
        try function_code_body_byte.append(@intFromEnum(local.locals_type));
    }

    for(code.instructions.items) |inst| {
        try function_code_body_byte.append(inst);
    }

    try section_code_body_byte.append(0x01);
    try section_code_body_byte.append(@intCast(function_code_body_byte.items.len));

    try section_code_header_byte.append(0x0A);
    try section_code_header_byte.append(@intCast(section_code_body_byte.items.len + function_code_body_byte.items.len));

    _ = try file.write(section_code_header_byte.items);
    _ = try file.write(section_code_body_byte.items);
    _ = try file.write(function_code_body_byte.items);

}

fn generateWASM(parser: *Parser, source: []u8, allocator: std.mem.Allocator) !Code {

    // Local Variables table
    var lv = VarTable.init(allocator);
    defer lv.deinit();

    var bytecode: std.ArrayList(Inst) = std.ArrayList(Inst).init(allocator);
    var locals: std.ArrayList(Local) = std.ArrayList(Local).init(allocator);

    for (parser.ast_roots.items) |roots| {
        try generateWASMCode(&parser.ast, roots, source, &bytecode, &locals, &lv);
    }

    try bytecode.append(0x0B);

    var code: Code = .{
        .size = 0,
        .locals = locals,
        .instructions = bytecode
    };
    return code;
}

fn generateWASMCodeFromAst(ast: *Ast, node_idx: u32, source: []u8, bytecode: *std.ArrayList(Inst), lv: *VarTable) !void {

    if (ast.nodes.items[node_idx].left != std.math.nan_u32) {
        try generateWASMCodeFromAst(ast, ast.nodes.items[node_idx].left, source, bytecode, lv);
    }

    if (ast.nodes.items[node_idx].right != std.math.nan_u32) {
        try generateWASMCodeFromAst(ast, ast.nodes.items[node_idx].right, source, bytecode, lv);
    }

    switch (ast.nodes.items[node_idx].type) {
        .add => try bytecode.append(@intFromEnum(OpCode.i32_add)),
        .sub => try bytecode.append(@intFromEnum(OpCode.i32_sub)),
        .mult => try bytecode.append(@intFromEnum(OpCode.i32_mult)),
        .div => try bytecode.append(@intFromEnum(OpCode.i32_div_s)), // What is the difference between div_s and div_u?
        .int_literal => {
            var int: i32 = 0;
            if (std.fmt.parseInt(i32, source[ast.nodes.items[node_idx].loc.start..ast.nodes.items[node_idx].loc.end], 10)) |out| {
                int = out;
            } else |err| {
                std.debug.print("Error while parsing int literal: {any}\n", .{err});
            }
            try bytecode.append(@intFromEnum(OpCode.i32_const));
            try bytecode.append(@intCast(int));
        },
//        .float_literal => {
//            var float: f32 = 0.0;
//            if (std.fmt.parseFloat(f32, source[ast.nodes.items[node_idx].loc.start..ast.nodes.items[node_idx].loc.end])) |out| {
//                float = out;
//            } else |err| {
//                std.debug.print("Error while parsing float literal: {any}\n", .{err});
//            }
//            pool.emitBytecodeAdd(.op_constant, pool.addConstant(.{.float = float}));
//        },
//        .bool_literal => {
//            var boolean: bool = false;
//            if (source[ast.nodes.items[node_idx].loc.start] == 't') {
//                boolean = true;
//            } else {
//                boolean = false;
//            }
//            pool.emitBytecodeAdd(.op_constant, pool.addConstant(.{.boolean = boolean}));
//        },
//        .bool_not => pool.emitBytecodeOp(.op_not),
//        .bool_and => pool.emitBytecodeOp(.op_and),
//        .bool_or => pool.emitBytecodeOp(.op_or),
//        .negate => pool.emitBytecodeOp(.op_negate),
//        .greater => pool.emitBytecodeOp(.op_greater),
//        .lesser => pool.emitBytecodeOp(.op_less),
//        .greater_equal => pool.emitBytecodeOp(.op_greater_than),
//        .lesser_equal => pool.emitBytecodeOp(.op_less_than),
//        .equal_equal => pool.emitBytecodeOp(.op_equal),
//        .not_equal => pool.emitBytecodeOp(.op_not_equal),
        .identifier => {
            const name: []u8 = source[ast.nodes.items[node_idx].loc.start..ast.nodes.items[node_idx].loc.end];
            try bytecode.append(@intFromEnum(OpCode.local_get));
            try bytecode.append(@intCast(lv.getByName(name)));
            // TODO: Add check for identifier not declared
        },
        .assign_stmt => {
            const left = ast.nodes.items[node_idx].left;
            const right = ast.nodes.items[node_idx].right;
            try generateWASMCodeFromAst(ast, right, source, bytecode, lv);
            const name: []u8 = source[ast.nodes.items[left].loc.start..ast.nodes.items[left].loc.end];
            // TODO: Add check for identifier not declared
            try bytecode.append(@intFromEnum(OpCode.local_set));
            try bytecode.append(@intCast(lv.getByName(name)));
        },
        else => {},
    }
}

pub fn generateWASMCode(ast: *Ast, node_idx: u32, source: []u8, bytecode: *std.ArrayList(Inst), locals: *std.ArrayList(Local), lv: *VarTable) !void {
    // generateCodeFromAst(ast, node, source, pool);
    // pool.emitBytecodeOp(.op_return);

    switch (ast.nodes.items[node_idx].type) {
        .var_stmt => {
            const node = ast.nodes.items[node_idx];
            const symbol_entry = SymbolTable.varTable.get(node.idx);
            try generateWASMCodeFromAst(ast, symbol_entry.expr_node, source, bytecode, lv);
            var value: VariableValue = undefined;
            switch(symbol_entry.type){
                .t_int => {
                    value = .{.int = 0};
                },
                .t_float => {
                    value = .{.float = 0.0};
                },
                .t_bool => {
                    value = .{.boolean = false};
                },
            }
            var index = try lv.add(symbol_entry.name, value);

            try locals.append(.{.locals = 1, .locals_type = ValueType.i32});

            try bytecode.append(@intFromEnum(OpCode.local_set));
            try bytecode.append(@intCast(index));
        },
        .print_stmt => {
            const left = ast.nodes.items[node_idx].left;
            try generateWASMCodeFromAst(ast, left, source, bytecode, lv);
            try bytecode.append(@intFromEnum(OpCode.call));
            try bytecode.append(0x00);
        },
        .assign_stmt => {
            const left = ast.nodes.items[node_idx].left;
            const right = ast.nodes.items[node_idx].right;
            try generateWASMCodeFromAst(ast, right, source, bytecode, lv);
            const name: []u8 = source[ast.nodes.items[left].loc.start..ast.nodes.items[left].loc.end];
            // TODO: Add check for identifier not declared
            try bytecode.append(@intFromEnum(OpCode.local_set));
            try bytecode.append(@intCast(lv.getByName(name)));
        },
        else => {}
    }

    // pool.emitBytecodeOp(.op_return);
}
//fn generateCodeFromAst(ast: *Ast, node_idx: u32, source: []u8, pool: *ByteCodePool) void {
//    if (ast.nodes.items[node_idx].left != std.math.nan_u32) {
//        generateCodeFromAst(ast, ast.nodes.items[node_idx].left, source, pool);
//    }
//
//    if (ast.nodes.items[node_idx].right != std.math.nan_u32) {
//        generateCodeFromAst(ast, ast.nodes.items[node_idx].right, source, pool);
//    }
//
//    switch (ast.nodes.items[node_idx].type) {
//        .add => pool.emitBytecodeOp(.op_add),
//        .sub => pool.emitBytecodeOp(.op_sub),
//        .mult => pool.emitBytecodeOp(.op_mult),
//        .div => pool.emitBytecodeOp(.op_div),
//        .int_literal => {
//            var int: i32 = 0;
//            if (std.fmt.parseInt(i32, source[ast.nodes.items[node_idx].loc.start..ast.nodes.items[node_idx].loc.end], 10)) |out| {
//                int = out;
//            } else |err| {
//                std.debug.print("Error while parsing int literal: {any}\n", .{err});
//            }
//            pool.emitBytecodeAdd(.op_constant, pool.addConstant(.{.int = int}));
//        },
//        .float_literal => {
//            var float: f32 = 0.0;
//            if (std.fmt.parseFloat(f32, source[ast.nodes.items[node_idx].loc.start..ast.nodes.items[node_idx].loc.end])) |out| {
//                float = out;
//            } else |err| {
//                std.debug.print("Error while parsing float literal: {any}\n", .{err});
//            }
//            pool.emitBytecodeAdd(.op_constant, pool.addConstant(.{.float = float}));
//        },
//        .bool_literal => {
//            var boolean: bool = false;
//            if (source[ast.nodes.items[node_idx].loc.start] == 't') {
//                boolean = true;
//            } else {
//                boolean = false;
//            }
//            pool.emitBytecodeAdd(.op_constant, pool.addConstant(.{.boolean = boolean}));
//        },
//        .bool_not => pool.emitBytecodeOp(.op_not),
//        .bool_and => pool.emitBytecodeOp(.op_and),
//        .bool_or => pool.emitBytecodeOp(.op_or),
//        .negate => pool.emitBytecodeOp(.op_negate),
//        .greater => pool.emitBytecodeOp(.op_greater),
//        .lesser => pool.emitBytecodeOp(.op_less),
//        .greater_equal => pool.emitBytecodeOp(.op_greater_than),
//        .lesser_equal => pool.emitBytecodeOp(.op_less_than),
//        .equal_equal => pool.emitBytecodeOp(.op_equal),
//        .not_equal => pool.emitBytecodeOp(.op_not_equal),
//        .identifier => {
//            const name: []u8 = source[ast.nodes.items[node_idx].loc.start..ast.nodes.items[node_idx].loc.end];
//            // TODO: Add check for identifier not declared
//            pool.emitBytecodeAdd(.op_unload_gv, @intCast(pool.global_var_tables.values.getIndex(name).?));
//        },
//        .assign_stmt => {
//            const left = ast.nodes.items[node_idx].left;
//            const right = ast.nodes.items[node_idx].right;
//            generateCodeFromAst(ast, right, source, pool);
//            const name: []u8 = source[ast.nodes.items[left].loc.start..ast.nodes.items[left].loc.end];
//            // TODO: Add check for identifier not declared
//            pool.emitBytecodeAdd(.op_load_gv, @intCast(pool.global_var_tables.values.getIndex(name).?));
//        },
//        else => {},
//    }
//}
//
//pub fn generateCode(ast: *Ast, node_idx: u32, source: []u8, pool: *ByteCodePool) void {
//    // generateCodeFromAst(ast, node, source, pool);
//    // pool.emitBytecodeOp(.op_return);
//
//    switch (ast.nodes.items[node_idx].type) {
//        .var_stmt => {
//            const node = ast.nodes.items[node_idx];
//            const symbol_entry = Symbol.varTable.get(node.symbol_idx);
//            generateCodeFromAst(ast, symbol_entry.expr_node, source, pool);
//            var value: Value = undefined;
//            switch(symbol_entry.type){
//                .t_int => {
//                    value = .{.int = 0};
//                },
//                .t_float => {
//                    value = .{.float = 0.0};
//                },
//                .t_bool => {
//                    value = .{.boolean = false};
//                },
//            }
//            pool.global_var_tables.values.put(symbol_entry.name, value) catch |err|{
//                std.debug.print("Unable to create global variable entry: {}", .{err});
//            };
//            pool.emitBytecodeAdd(.op_load_gv, @intCast(pool.global_var_tables.values.getIndex(symbol_entry.name).?));
//        },
//        .print_stmt => {
//            const left = ast.nodes.items[node_idx].left;
//            generateCodeFromAst(ast, left, source, pool);
//            pool.emitBytecodeOp(.op_print);
//        },
//        .assign_stmt => {
//            const left = ast.nodes.items[node_idx].left;
//            const right = ast.nodes.items[node_idx].right;
//            generateCodeFromAst(ast, right, source, pool);
//            const name: []u8 = source[ast.nodes.items[left].loc.start..ast.nodes.items[left].loc.end];
//            // TODO: Add check for identifier not declared
//            pool.emitBytecodeAdd(.op_load_gv, @intCast(pool.global_var_tables.values.getIndex(name).?));
//        },
//        else => {}
//    }
//    // pool.emitBytecodeOp(.op_return);
//}
