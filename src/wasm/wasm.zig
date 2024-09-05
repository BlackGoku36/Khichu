const std = @import("std");

// Sections and their order
// 0 = custom section
// 1 = type section
// 2 = import section
// 3 = function section
// 4 = table section
// 5 = memory section
// 6 = global section
// 7 = export section
// 8 = start section
// 9 = element section
// 10 =  code section
// 11 =  data section
// 12 =  data count section

pub const Module = struct {
    magic: u32 = 0x0061736D,
    version: u32 = 0x01000000,
};

pub const SectionType = struct {
    id: u8 = 0x01,
    size: u32, //leb128 (size in bytes)
    func_type: std.ArrayList(FunctionType), // leb128 len + content
};

// https://webassembly.github.io/spec/core/binary/types.html#number-types
pub const ValueType = enum(u8) { i32 = 0x7F, i64 = 0x7E, f32 = 0x7D, f64 = 0x7C };
pub const FunctionType = struct {
    id: u8 = 0x60,
    params: std.ArrayList(u8), // leb128 size + content
    results: std.ArrayList(u8), // leb128 size + content
};

pub const FunctionSection = struct {
    id: u8 = 0x03,
    size: u32, //leb128 (size in bytes)
    types: std.ArrayList(u32), //leb128 len + leb128 contents
};

pub const ExportSection = struct {
    id: u8 = 0x07,
    size: u32, //leb128 (size in bytes)
    exports: std.ArrayList(Export), // leb128 len + content
};

pub const Export = struct {
    name: []u8,
    tag: u8, //func = 0, table = 1, mem = 2, global = 3
    idx: u32, //leb128
};

pub const CodeSection = struct {
    id: u8 = 0x0A,
    size: u32, // leb128 (size in bytes)
    codes: std.ArrayList(Code),
};

pub const Code = struct {
    size: u32, //leb128 (size in bytes)
    locals: std.ArrayList(Local),
    instructions: std.ArrayList(Inst),
};

// (local i32) (local i32) becomes [2 i32]
// (local i32) (local f32) (local i32) becomes [1 i32, 1 f32, 1 i32]
// Basically all local variable of same type declared in succession will be merged into same Local element
pub const Local = struct {
    locals: u32, //leb128 len (TODO: fr?)
    locals_type: ValueType,
};

// https://webassembly.github.io/spec/core/binary/instructions.html
pub const Inst = u8;
pub const OpCode = enum(u8) {
    // Control Instruction
    @"if" = 0x04,
    @"else" = 0x05,
    end = 0x0B,
    call = 0x10,
    @"return" = 0x0F,
    // Variable Instruction
    local_get = 0x20,
    local_set = 0x21,
    local_tee = 0x22,
    global_get = 0x23,
    global_set = 0x24,
    // Numeric Instruction
    i32_const = 0x41,
    i64_const = 0x42,
    f32_const = 0x43,
    f64_const = 0x44,
    // i32
    i32_add = 0x6A,
    i32_sub = 0x6B,
    i32_mult = 0x6C,
    i32_div_s = 0x6D,
    i32_div_u = 0x6E,
    i32_and = 0x71,
    i32_or = 0x72,
    i32_xor = 0x73,
    i32_shl = 0x74,
    i32_shr_s = 0x75,
    i32_shr_u = 0x76,
    i32_eqz = 0x45,
    i32_eq = 0x46,
    i32_ne = 0x47,
    i32_lt_s = 0x48,
    i32_lt_u = 0x49,
    i32_gt_s = 0x4A,
    i32_gt_u = 0x4B,
    i32_le_s = 0x4C,
    i32_le_u = 0x4D,
    i32_ge_s = 0x4E,
    i32_ge_u = 0x4F,
    // f32
    f32_add = 0x92,
    f32_sub = 0x93,
    f32_mult = 0x94,
    f32_div = 0x95,
    f32_neg = 0x8C,
};
