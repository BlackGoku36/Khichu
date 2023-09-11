const std = @import("std");

pub const Type = enum {
    t_int, t_float, t_bool,

    pub fn str(var_type: Type) []const u8{
        switch (var_type) {
            .t_int => return "t_int",
            .t_float => return "t_float",
            .t_bool => return "t_bool",
        }
    }
};

const varSymbol = struct {
    // Is it ok to pass as slice? As original source would need to be alive,
    // is it ok to keep source code alive all the time?
    name: []u8,
    type: Type,
    expr_node: u32,
};

pub const Symbol = struct {
    pub var varTable: std.MultiArrayList(varSymbol) = undefined;
    var allocator: std.mem.Allocator = undefined;

    pub fn createTables(allocator_: std.mem.Allocator) void {
        varTable = std.MultiArrayList(varSymbol){};
        allocator = allocator_;
    }

    pub fn destroyTables() void {
        varTable.deinit(allocator);
    }

    pub fn appendVar(symbol: varSymbol) usize {
        varTable.append(allocator, symbol) catch |err|{
            std.debug.print("Unable to create entry in varTable symbol table: {}", .{err});
        };

        return varTable.len - 1;
    }

    pub fn printVar() void {
        for (varTable.items(.name), varTable.items(.type), varTable.items(.expr_node)) |name, var_type, expr_node| {
            std.debug.print("{s}, {s}, {d}\n", .{name, var_type.str(), expr_node});
        }
    } 
};