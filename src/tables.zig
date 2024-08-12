const std = @import("std");
const Ast = @import("ast.zig").Ast;

pub const Type = enum {
    t_int,
    t_float,
    t_bool,
    t_void,

    pub fn str(var_type: Type) []const u8 {
        switch (var_type) {
            .t_int => return "t_int",
            .t_float => return "t_float",
            .t_bool => return "t_bool",
            .t_void => return "t_void",
        }
    }
};

const VarSymbol = struct {
    // Is it ok to pass as slice? As original source would need to be alive,
    // is it ok to keep source code alive all the time?
    name: []u8,
    type: Type,
    // TODO: is this needed?
    expr_node: u32,
};

pub const SymbolTable = struct {
    pub var varTable: std.MultiArrayList(VarSymbol) = undefined;
    var allocator: std.mem.Allocator = undefined;

    pub fn createTables(allocator_: std.mem.Allocator) void {
        varTable = std.MultiArrayList(VarSymbol){};
        allocator = allocator_;
    }

    pub fn destroyTables() void {
        varTable.deinit(allocator);
    }

    pub fn appendVar(symbol: VarSymbol) usize {
        varTable.append(allocator, symbol) catch |err| {
            std.debug.print("Unable to create entry in varTable symbol table: {}", .{err});
        };

        return varTable.len - 1;
    }

    pub fn exists(name: []u8) bool {
        var exist: bool = false;
        for (varTable.items(.name)) |var_name| {
            if (std.mem.eql(u8, name, var_name)) exist = true;
        }
        return exist;
    }

    pub fn findByName(name: []u8) ?VarSymbol {
        for (0.., varTable.items(.name)) |i, var_name| {
            if (std.mem.eql(u8, name, var_name)) {
                return varTable.get(i);
            }
        }
        return null;
    }

    pub fn printVar() void {
        for (varTable.items(.name), varTable.items(.type), varTable.items(.expr_node)) |name, var_type, expr_node| {
            std.debug.print("{s}, {s}, {d}\n", .{ name, var_type.str(), expr_node });
        }
    }
};

const ExprSymbol = struct {
    type: Type,
};

pub const ExprTypeTable = struct {
    pub var table: std.ArrayList(ExprSymbol) = undefined;

    pub fn createTable(allocator: std.mem.Allocator) void {
        table = std.ArrayList(ExprSymbol).init(allocator);
    }

    pub fn appendExprType(expr_type: Type) usize {
        table.append(.{ .type = expr_type }) catch |err| {
            std.debug.print("Unable to create entry in ExprSymbol: {}", .{err});
        };
        return table.items.len - 1;
    }

    pub fn printExprTypes() void {
        for (0.., table.items) |i, expr_type| {
            std.debug.print("{d}: {s}\n", .{ i, expr_type.type.str() });
        }
    }

    pub fn destroyTable() void {
        table.deinit();
    }
};

pub const FnCallSymbol = struct {
    name_node: usize,
    arguments_start: usize,
    arguments_end: usize,
};

pub const FnCallTable = struct {
    pub var table: std.ArrayList(FnCallSymbol) = undefined;
    pub var arguments: std.ArrayList(usize) = undefined;

    pub fn createTable(allocator: std.mem.Allocator) void {
        table = std.ArrayList(FnCallSymbol).init(allocator);
        arguments = std.ArrayList(usize).init(allocator);
    }

    pub fn appendFunction(fn_call_symbol: FnCallSymbol) usize {
        table.append(fn_call_symbol) catch |err| {
            std.debug.print("Unable to create entry in FnCallTable: {}", .{err});
        };
        return table.items.len - 1;
    }

    pub fn printFunctions(source: []u8, ast: Ast) void {
        for (0.., table.items) |i, function| {
            const name = ast.nodes.items[function.name_node];
            std.debug.print("{d}: {s}\n", .{ i, source[name.loc.start..name.loc.end] });
        }
    }

    pub fn destroyTable() void {
        table.deinit();
        arguments.deinit();
    }
};

pub const FnSymbol = struct {
    name_node: usize,
    return_type: Type,
    parameter_start: usize,
    parameter_end: usize,
    body_nodes_start: usize,
    body_nodes_end: usize,
};

pub const FnParameterSymbol = struct {
    name_node: usize,
    parameter_type: Type,
};

pub const FnTable = struct {
    pub var table: std.ArrayList(FnSymbol) = undefined;
    pub var parameters: std.ArrayList(FnParameterSymbol) = undefined;

    pub fn createTable(allocator: std.mem.Allocator) void {
        table = std.ArrayList(FnSymbol).init(allocator);
        parameters = std.ArrayList(FnParameterSymbol).init(allocator);
    }

    pub fn appendFunction(fn_symbol: FnSymbol) usize {
        table.append(fn_symbol) catch |err| {
            std.debug.print("Unable to create entry in FnTable: {}", .{err});
        };
        return table.items.len - 1;
    }

    pub fn getMainIdx(source: []u8, ast: Ast) !u32 {
        for (0.., table.items) |i, function| {
            const name = ast.nodes.items[function.name_node];
            const function_name = source[name.loc.start..name.loc.end];
            if (std.mem.eql(u8, function_name, "main")) {
                return @intCast(i);
            }
        }
        return error.MainNotFound;
    }

    pub fn getFunctionIdx(fn_call_name_node: usize, source: []u8, ast: Ast) !u32 {
        for (0.., table.items) |i, function| {
            const name = ast.nodes.items[function.name_node];
            const call_name = ast.nodes.items[fn_call_name_node];
            const function_name = source[name.loc.start..name.loc.end];
            const function_call_name = source[call_name.loc.start..call_name.loc.end];
            std.debug.print("function_name: {s}\n", .{function_name});
            std.debug.print("function_call_name: {s}\n", .{function_call_name});
            if (std.mem.eql(u8, function_name, function_call_name)) {
                return @intCast(i);
            }
        }
        return error.FunctionNotFound;
    }

    pub fn printFunctions(source: []u8, ast: Ast) void {
        for (0.., table.items) |i, function| {
            const name = ast.nodes.items[function.name_node];
            std.debug.print("{d}: {s}\n", .{ i, source[name.loc.start..name.loc.end] });
            std.debug.print("nodes: ", .{});
            for (function.body_nodes_start..function.body_nodes_end) |node_idx| {
                std.debug.print("{d}, ", .{node_idx});
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn destroyTable() void {
        table.deinit();
        parameters.deinit();
    }
};
