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

pub const SectionType = struct{
    id: u8 = 0x01,
    size: u32, //leb128 (size in bytes)
    func_type: std.ArrayList(FunctionType)// leb128 len + content
};

pub const ValueType = u8; // i32 = 0x7F, i64 = 0x7E, f32 = 0x7D, f64 = 0x7C

pub const FunctionType = struct{
    id: u8 = 0x60,
    params: std.ArrayList(ValueType), // leb128 size + content
    results: std.ArrayList(ValueType)// leb128 size + content
};

pub const FunctionSection = struct{
    id: u8 = 0x03,
    size: u32, //leb128 (size in bytes)
    types: std.ArrayList(u32) //leb128 len + leb128 contents
};

pub const ExportSection = struct{
    id: u8 = 0x07,
    size: u32, //leb128 (size in bytes)
    exports: std.ArrayList(Export) // leb128 len + content
};

pub const Export = struct{
    name: []u8,
    tag: u8, //func = 0, table = 1, mem = 2, global = 3
    idx: u32 //leb128
};

pub const CodeSection = struct{
    id: u8 = 0x0A,
    size: u32, // leb128 (size in bytes)
    codes: std.ArrayList(Code)
};

pub const Code = struct{
    size: u32, //leb128 (size in bytes)
    locals: std.ArrayList(Local),
    instructions: std.ArrayList(Inst)
};

// (local i32) (local i32) becomes [2 i32]
// (local i32) (local f32) (local i32) becomes [1 i32, 1 f32, 1 i32]
// Basically all local variable of same type declared in succession will be merged into same Local element
pub const Local = struct{
    locals: u32, //leb128 len (TODO: fr?)
    locals_type: ValueType
};

pub const Inst = u8;
