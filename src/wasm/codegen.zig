const std = @import("std");
const leb = std.leb;

const Ast = @import("../ast.zig").Ast;
const tables = @import("../tables.zig");
const SymbolTable = tables.SymbolTable;
const ExprTypeTable = tables.ExprTypeTable;
const FnTable = tables.FnTable;
const FnSymbol = tables.FnSymbol;
const FnCallTable = tables.FnCallTable;
const Parser = @import("../parser.zig").Parser;

const wasm = @import("wasm.zig");
const Module = wasm.Module;
const SectionType = wasm.SectionType;
const FunctionType = wasm.FunctionType;
const FunctionSection = wasm.FunctionSection;
const Code = wasm.Code;
const Local = wasm.Local;
const Inst = wasm.Inst;
const ValueType = wasm.ValueType;
const OpCode = wasm.OpCode;

const nan_u32 = 0x7FC00000;

pub const VariableValueType = enum { int, float, boolean };
pub const VariableValue = union(VariableValueType) {
    int: i32,
    float: f32,
    boolean: bool,
};
pub const Variable = struct { identifier: []u8, value: VariableValue };

pub const VarTable = struct {
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
        try gv_table.variables.append(.{ .identifier = identifier, .value = value });
        return gv_table.variables.items.len - 1;
    }

    pub fn get(gv_table: *VarTable, index: u32) Variable {
        return gv_table.variables[index];
    }

    pub fn getByName(gv_table: *VarTable, identifier: []u8) usize {
        for (gv_table.variables.items, 0..) |variable, i| {
            if (std.mem.eql(u8, variable.identifier, identifier)) {
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

    var magic: [4]u8 = undefined;
    std.mem.writeInt(u32, &magic, module.magic, .big);
    var version: [4]u8 = undefined;
    std.mem.writeInt(u32, &version, module.version, .big);
    _ = try file.write(&magic);
    _ = try file.write(&version);

    var sectionType: SectionType = .{ .size = 0, .func_type = std.ArrayList(FunctionType).init(allocator) };
    defer sectionType.func_type.deinit();
    try sectionType.func_type.append(.{ .params = std.ArrayList(u8).init(allocator), .results = std.ArrayList(u8).init(allocator) });
    try sectionType.func_type.append(.{ .params = std.ArrayList(u8).init(allocator), .results = std.ArrayList(u8).init(allocator) });
    for (0..FnTable.table.items.len) |_| {
        try sectionType.func_type.append(.{ .params = std.ArrayList(u8).init(allocator), .results = std.ArrayList(u8).init(allocator) });
    }
    defer {
        for (sectionType.func_type.items) |sec| {
            sec.params.deinit();
            sec.results.deinit();
        }
    }
    // TODO: Remove this hard coding someday
    try sectionType.func_type.items[0].params.append(@intFromEnum(ValueType.f32));
    try sectionType.func_type.items[1].params.append(@intFromEnum(ValueType.i32));

    var header_bytes: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer header_bytes.deinit();
    const header_bytes_writer = header_bytes.writer();

    var body_bytes: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer body_bytes.deinit();
    const body_bytes_writer = body_bytes.writer();

    //try body_bytes.append(@intCast(sectionType.func_type.items.len));
    try leb.writeULEB128(body_bytes_writer, sectionType.func_type.items.len);

    for (sectionType.func_type.items) |fns| {
        try leb.writeULEB128(body_bytes_writer, fns.id);
        try leb.writeULEB128(body_bytes_writer, fns.params.items.len);
        //try body_bytes.append(fns.id);
        //try body_bytes.append(@intCast(fns.params.items.len));
        for (fns.params.items) |param| {
            try leb.writeULEB128(body_bytes_writer, param);
            //try body_bytes.append(param);
        }
        try leb.writeULEB128(body_bytes_writer, fns.results.items.len);
        //try body_bytes.append(@intCast(fns.results.items.len));
        for (fns.results.items) |result| {
            try leb.writeULEB128(body_bytes_writer, result);
            //            try body_bytes.append(result);
        }
    }
    try leb.writeULEB128(header_bytes_writer, sectionType.id);
    try leb.writeULEB128(header_bytes_writer, body_bytes.items.len);
    //    try header_bytes.append(sectionType.id);
    //    try header_bytes.append(@intCast(body_bytes.items.len));

    _ = try file.write(header_bytes.items);
    _ = try file.write(body_bytes.items);

    _ = try file.write(&[_]u8{ 0x02, 0x19, 0x02, 0x03, 0x73, 0x74, 0x64, 0x05, 0x70, 0x72, 0x69, 0x6E, 0x74, 0x00, 0x00, 0x03, 0x73, 0x74, 0x64, 0x05, 0x70, 0x72, 0x69, 0x6E, 0x74, 0x00, 0x01 });

    var functionSection: FunctionSection = .{
        .size = 0,
        .types = std.ArrayList(u32).init(allocator),
    };
    //const function_section_types_writer = functionSection.types.writer();
    defer functionSection.types.deinit();

    for (0..FnTable.table.items.len) |i| {
        //try leb.writeULEB128(function_section_types_writer, i + 2);
        try functionSection.types.append(@intCast(i + 2));
    }

    var func_sec_header_bytes: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer func_sec_header_bytes.deinit();
    const func_sec_header_bytes_writer = func_sec_header_bytes.writer();

    var func_sec_body_bytes: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer func_sec_body_bytes.deinit();
    const func_sec_body_bytes_writer = func_sec_body_bytes.writer();

    //try func_sec_body_bytes.append(@intCast(functionSection.types.items.len));
    try leb.writeULEB128(func_sec_body_bytes_writer, functionSection.types.items.len);
    for (functionSection.types.items) |type_idx| {
        try leb.writeULEB128(func_sec_body_bytes_writer, type_idx);
        //try func_sec_body_bytes.append(@intCast(type_idx));
    }

    try leb.writeULEB128(func_sec_header_bytes_writer, functionSection.id);
    try leb.writeULEB128(func_sec_header_bytes_writer, func_sec_body_bytes.items.len);
    //try func_sec_header_bytes.append(functionSection.id);
    //try func_sec_header_bytes.append(@intCast(func_sec_body_bytes.items.len));

    _ = try file.write(func_sec_header_bytes.items);
    _ = try file.write(func_sec_body_bytes.items);

    // export func hard coded
    //_ = try file.write(&[_]u8{0x07,0x08,0x01,0x04,0x6D,0x61,0x69,0x6E,0x00,0x01});
    // hard code start section
    //const main_idx: u8 = @intCast(try FnTable.getMainIdx(source, parser.ast));
    const main_idx: u32 = try FnTable.getMainIdx(source, parser.ast);
    //_ = try file.write(&[_]u8{ 0x08, 0x01, main_idx + 2 });
    _ = try file.write(&[_]u8{ 0x08, 0x01 });
    try leb.writeULEB128(file.writer(), main_idx + 2);

    var code: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer code.deinit();
    const code_writer = code.writer();

    for (FnTable.table.items) |fn_| {
        var fn_code = try generateWASM(parser, source, fn_, allocator);
        defer {
            fn_code.locals.deinit();
            fn_code.instructions.deinit();
        }
        var code_body_byte: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
        defer code_body_byte.deinit();
        const code_body_byte_writer = code_body_byte.writer();

        //try code_body_byte.append(@intCast(fn_code.locals.items.len));
        try leb.writeULEB128(code_body_byte_writer, fn_code.locals.items.len);
        for (fn_code.locals.items) |local| {
            try leb.writeULEB128(code_body_byte_writer, local.locals);
            try leb.writeULEB128(code_body_byte_writer, @intFromEnum(local.locals_type));
            //try code_body_byte.append(@intCast(local.locals));
            //try code_body_byte.append(@intFromEnum(local.locals_type));
        }

        for (fn_code.instructions.items) |inst| {
            try code_body_byte.append(inst);
        }
        //const code_size: u8 = @intCast(code_body_byte.items.len);

        //try code.append(code_size);
        try leb.writeULEB128(code_writer, code_body_byte.items.len);
        for (code_body_byte.items) |byte| {
            try code.append(byte);
        }
    }

    var section_code_header_byte: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer section_code_header_byte.deinit();
    const section_code_header_byte_writer = section_code_header_byte.writer();

    var section_code_body_byte: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer section_code_body_byte.deinit();
    const section_code_body_byte_writer = section_code_body_byte.writer();

    //try section_code_body_byte.append(@intCast(FnTable.table.items.len));
    try leb.writeULEB128(section_code_body_byte_writer, FnTable.table.items.len);

    try section_code_header_byte.append(0x0A);
//    try section_code_header_byte.append(@intCast(section_code_body_byte.items.len + code.items.len));
//    try leb.writeULEB128(section_code_header_byte_writer, 0x0A);
    try leb.writeULEB128(section_code_header_byte_writer, section_code_body_byte.items.len + code.items.len);

    _ = try file.write(section_code_header_byte.items);
    _ = try file.write(section_code_body_byte.items);
    _ = try file.write(code.items);
}

fn generateWASM(parser: *Parser, source: []u8, fn_: FnSymbol, allocator: std.mem.Allocator) !Code {

    // Local Variables table
    var lv = VarTable.init(allocator);
    defer lv.deinit();

    var bytecode: std.ArrayList(Inst) = std.ArrayList(Inst).init(allocator);
    var locals: std.ArrayList(Local) = std.ArrayList(Local).init(allocator);
    for (parser.ast_roots.items[fn_.body_nodes_start..fn_.body_nodes_end]) |roots| {
        try generateWASMCode(&parser.ast, roots, source, &bytecode, &locals, &lv);
    }

    try bytecode.append(0x0B);

    const code: Code = .{ .size = 0, .locals = locals, .instructions = bytecode };
    return code;
}

fn generateWASMCodeFromAst(ast: *Ast, node_idx: u32, source: []u8, bytecode: *std.ArrayList(Inst), lv: *VarTable) !void {
    const left_exist = ast.nodes.items[node_idx].left != nan_u32;
    const right_exist = ast.nodes.items[node_idx].right != nan_u32;

    const bytecode_writer = bytecode.*.writer();

    if (left_exist) {
        try generateWASMCodeFromAst(ast, ast.nodes.items[node_idx].left, source, bytecode, lv);
    }

    if (right_exist) {
        try generateWASMCodeFromAst(ast, ast.nodes.items[node_idx].right, source, bytecode, lv);
    }

    switch (ast.nodes.items[node_idx].type) {
        .add => {
            const expr_type = ExprTypeTable.table.items[ast.nodes.items[node_idx].idx].type;
            switch (expr_type) {
                .t_int => try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.i32_add)),//try bytecode.append(@intFromEnum(OpCode.i32_add)),
                .t_float => try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.f32_add)),//try bytecode.append(@intFromEnum(OpCode.f32_add)),
                .t_bool => unreachable,
            }
        },
        .sub => {
            const expr_type = ExprTypeTable.table.items[ast.nodes.items[node_idx].idx].type;
            switch (expr_type) {
                .t_int => try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.i32_sub)),//try bytecode.append(@intFromEnum(OpCode.i32_sub)),
                .t_float => try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.f32_sub)),//try bytecode.append(@intFromEnum(OpCode.f32_sub)),
                .t_bool => unreachable,
            }
        },
        .mult => {
            const expr_type = ExprTypeTable.table.items[ast.nodes.items[node_idx].idx].type;
            switch (expr_type) {
                .t_int => try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.i32_mult)),//try bytecode.append(@intFromEnum(OpCode.i32_mult)),
                .t_float => try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.f32_mult)),//try bytecode.append(@intFromEnum(OpCode.f32_mult)),
                .t_bool => unreachable,
            }
        },
        .div => {
            const expr_type = ExprTypeTable.table.items[ast.nodes.items[node_idx].idx].type;
            switch (expr_type) {
                .t_int => try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.i32_div_s)),//try bytecode.append(@intFromEnum(OpCode.i32_div_s)),
                .t_float => try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.f32_div)),//try bytecode.append(@intFromEnum(OpCode.f32_div)),
                .t_bool => unreachable,
            }
        },
        .int_literal => {
            var int: i32 = 0;
            if (std.fmt.parseInt(i32, source[ast.nodes.items[node_idx].loc.start..ast.nodes.items[node_idx].loc.end], 10)) |out| {
                int = out;
            } else |err| {
                std.debug.print("Error while parsing int literal: {any}\n", .{err});
            }
            try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.i32_const));
            try leb.writeILEB128(bytecode_writer, int);
            //try bytecode.append(@intFromEnum(OpCode.i32_const));
            //try bytecode.append(@intCast(int));
        },
        .float_literal => {
            var float: f32 = 0.0;
            if (std.fmt.parseFloat(f32, source[ast.nodes.items[node_idx].loc.start..ast.nodes.items[node_idx].loc.end])) |out| {
                float = out;
            } else |err| {
                std.debug.print("Error while parsing float literal: {any}\n", .{err});
            }
            //try bytecode.append(@intFromEnum(OpCode.f32_const));
            try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.f32_const));
            // Bytes of float in little-endian (by IEEE 754 bit pattern)
            const float_byte: u32 = @byteSwap(@as(u32, @bitCast(float)));
            try bytecode.append(@truncate(float_byte >> 24));
            try bytecode.append(@truncate(float_byte >> 16));
            try bytecode.append(@truncate(float_byte >> 8));
            try bytecode.append(@truncate(float_byte));
        },
        .bool_literal => {
            try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.i32_const));
            //try bytecode.append(@intFromEnum(OpCode.i32_const));
            if (source[ast.nodes.items[node_idx].loc.start] == 't') {
                try bytecode.append(0x01);
            } else {
                try bytecode.append(0x00);
            }
        },
        .bool_not => {
            try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.i32_const));
            //try bytecode.append(@intFromEnum(OpCode.i32_const));
            try bytecode.append(0x01);
            try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.i32_xor));
            //try bytecode.append(@intFromEnum(OpCode.i32_xor));
        },
        .bool_and => try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.i32_and)), // try bytecode.append(@intFromEnum(OpCode.i32_and)),
        .bool_or => try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.i32_or)), // try bytecode.append(@intFromEnum(OpCode.i32_or)),
        .negate => {
            if (left_exist) {
                const left_node = ast.nodes.items[ast.nodes.items[node_idx].left];
                switch (left_node.type) {
                    .int_literal => {
                        // Multiply -1 with the value to get negative value
                        //try bytecode.append(@intFromEnum(OpCode.i32_const));
                        try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.i32_const));
                        try bytecode.append(0x7F); // -1 in LEB128
                        try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.i32_mult));
                        //try bytecode.append(@intFromEnum(OpCode.i32_mult));
                    },
                    .float_literal => {
                        try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.f32_neg));
                        //try bytecode.append(@intFromEnum(OpCode.f32_neg));
                    },
                    .identifier => {
                        const symbol_type = SymbolTable.findByName(source[left_node.loc.start..left_node.loc.end]).?.type;
                        switch (symbol_type) {
                            .t_int => {
                                // Multiply -1 with the value to get negative value
                                try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.i32_const));
                                //try bytecode.append(@intFromEnum(OpCode.i32_const));
                                try bytecode.append(0x7F); // -1 in LEB128
                                try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.i32_mult));
                                //try bytecode.append(@intFromEnum(OpCode.i32_mult));
                            },
                            .t_float => try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.f32_neg)), //try bytecode.append(@intFromEnum(OpCode.f32_neg)),
                            .t_bool => unreachable,
                        }
                    },
                    .bool_literal => unreachable,
                    .add, .sub, .mult, .div => {
                        const expr_type = ExprTypeTable.table.items[left_node.idx].type;
                        switch (expr_type) {
                            .t_int => {
                                // Multiply -1 with the value to get negative value
                                try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.i32_const));
                                //try bytecode.append(@intFromEnum(OpCode.i32_const));
                                try bytecode.append(0x7F); // -1 in LEB128
                                try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.i32_mult));
                                //try bytecode.append(@intFromEnum(OpCode.i32_mult));
                            },
                            .t_float => try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.f32_neg)), //try bytecode.append(@intFromEnum(OpCode.f32_neg)),
                            .t_bool => unreachable,
                        }
                    },
                    else => {},
                }
            }
        },
        // .greater => pool.emitBytecodeOp(.op_greater),
        // .lesser => pool.emitBytecodeOp(.op_less),
        // .greater_equal => pool.emitBytecodeOp(.op_greater_than),
        // .lesser_equal => pool.emitBytecodeOp(.op_less_than),
        // .equal_equal => pool.emitBytecodeOp(.op_equal),
        // .not_equal => pool.emitBytecodeOp(.op_not_equal),
        .identifier => {
            const name: []u8 = source[ast.nodes.items[node_idx].loc.start..ast.nodes.items[node_idx].loc.end];
            try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.local_get));
            try leb.writeULEB128(bytecode_writer, lv.getByName(name));
            //try bytecode.append(@intFromEnum(OpCode.local_get));
            //try bytecode.append(@intCast(lv.getByName(name)));
            // TODO: Add check for identifier not declared
        },
        .assign_stmt => {
            const left = ast.nodes.items[node_idx].left;
            const right = ast.nodes.items[node_idx].right;
            try generateWASMCodeFromAst(ast, right, source, bytecode, lv);
            const name: []u8 = source[ast.nodes.items[left].loc.start..ast.nodes.items[left].loc.end];
            // TODO: Add check for identifier not declared

            try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.local_set));
            try leb.writeULEB128(bytecode_writer, lv.getByName(name));
            //try bytecode.append(@intFromEnum(OpCode.local_set));
            //try bytecode.append(@intCast(lv.getByName(name)));
        },
        else => {},
    }
}

pub fn generateWASMCode(ast: *Ast, node_idx: u32, source: []u8, bytecode: *std.ArrayList(Inst), locals: *std.ArrayList(Local), lv: *VarTable) !void {
    // generateCodeFromAst(ast, node, source, pool);
    // pool.emitBytecodeOp(.op_return);

    const bytecode_writer = bytecode.*.writer();

    switch (ast.nodes.items[node_idx].type) {
        .var_stmt => {
            const node = ast.nodes.items[node_idx];
            const symbol_entry = SymbolTable.varTable.get(node.idx);
            try generateWASMCodeFromAst(ast, symbol_entry.expr_node, source, bytecode, lv);
            var value: VariableValue = undefined;
            switch (symbol_entry.type) {
                .t_int => {
                    value = .{ .int = 0 };
                    try locals.append(.{ .locals = 1, .locals_type = ValueType.i32 });
                },
                .t_float => {
                    value = .{ .float = 0.0 };
                    try locals.append(.{ .locals = 1, .locals_type = ValueType.f32 });
                },
                .t_bool => {
                    value = .{ .boolean = false };
                    try locals.append(.{ .locals = 1, .locals_type = ValueType.i32 });
                },
            }
            const index = try lv.add(symbol_entry.name, value);
            
            try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.local_set));
            try leb.writeULEB128(bytecode_writer, index);

            //try bytecode.append(@intFromEnum(OpCode.local_set));
            //try bytecode.append(@intCast(index));
        },
        .print_stmt => {
            const left_idx = ast.nodes.items[node_idx].left;
            try generateWASMCodeFromAst(ast, left_idx, source, bytecode, lv);
            const left_node = ast.nodes.items[left_idx];

            try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.call));
            //try bytecode.append(@intFromEnum(OpCode.call));
            
            switch (left_node.type) {
                .int_literal, .bool_literal => try bytecode.append(0x01),
                .float_literal => try bytecode.append(0x00),
                .identifier => {
                    const symbol_type = SymbolTable.findByName(source[left_node.loc.start..left_node.loc.end]).?.type;
                    switch (symbol_type) {
                        .t_int, .t_bool => try bytecode.append(0x01),
                        .t_float => try bytecode.append(0x00),
                    }
                },
                else => {
                    const expr_type = ExprTypeTable.table.items[left_node.idx].type;
                    switch (expr_type) {
                        .t_int, .t_bool => try bytecode.append(0x01),
                        .t_float => try bytecode.append(0x00),
                    }
                },
            }
        },
        .assign_stmt => {
            const left = ast.nodes.items[node_idx].left;
            const right = ast.nodes.items[node_idx].right;
            try generateWASMCodeFromAst(ast, right, source, bytecode, lv);
            const name: []u8 = source[ast.nodes.items[left].loc.start..ast.nodes.items[left].loc.end];
            // TODO: Add check for identifier not declared

            try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.local_set));
            try leb.writeULEB128(bytecode_writer, lv.getByName(name));
            //try bytecode.append(@intFromEnum(OpCode.local_set));
            //try bytecode.append(@intCast(lv.getByName(name)));
        },
        .fn_call => {
            const current_node_idx = ast.nodes.items[node_idx].idx;
            const function_idx = FnCallTable.table.items[current_node_idx].name_node;
            // const function_lit_node = ast.nodes.items[function_idx];
            const out_idx = try FnTable.getFunctionIdx(function_idx, source, ast.*);

            try leb.writeULEB128(bytecode_writer, @intFromEnum(OpCode.call));
            try leb.writeULEB128(bytecode_writer, out_idx + 2);
            //try bytecode.append(@intFromEnum(OpCode.call));
            //try bytecode.append(@intCast(out_idx + 2));
            std.debug.print("esist: {any}\n", .{out_idx + 2});
        },
        else => {},
    }
}
