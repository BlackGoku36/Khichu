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
        varTable.append(allocator, symbol) catch |err|{
            std.debug.print("Unable to create entry in varTable symbol table: {}", .{err});
        };

        return varTable.len - 1;
    }

    pub fn exists(name: []u8) bool{
        var exist:bool = false;
        for(varTable.items(.name)) |var_name|{
            if(std.mem.eql(u8, name, var_name)) exist = true;
        }
        return exist;
    }

    pub fn printVar() void {
        for (varTable.items(.name), varTable.items(.type), varTable.items(.expr_node)) |name, var_type, expr_node| {
            std.debug.print("{s}, {s}, {d}\n", .{name, var_type.str(), expr_node});
        }
    }
};

const ExprSymbol = struct{
	type:Type,
};

pub const ExprTypeTable = struct{
	pub var table: std.ArrayList(ExprSymbol) = undefined;

	pub fn createTable(allocator: std.mem.Allocator) void {
		table = std.ArrayList(ExprSymbol).init(allocator);
	}

	pub fn appendExprType(expr_type: Type) usize {
		table.append(.{.type = expr_type}) catch |err| {
			std.debug.print("Unable to create entry in ExprSymbol: {}", .{err});
		};
		return table.items.len - 1;
	}

	pub fn printExprTypes() void {
        for (0.., table.items) |i, expr_type| {
            std.debug.print("{d}: {s}\n", .{i, expr_type.type.str()});
        }
    }

	pub fn destroyTable() void {
		table.deinit();
	}
};
