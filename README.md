# Khichu

[Khichu](https://en.wikipedia.org/wiki/Khichu) is experimental programming language that targets WASM. We do our own code-generation from scratch instead of relying on LLVM or similar code-generation technologies.

This is project done during free time.

## Compile and Run

Write the code in `demo.k` and do:

```
# Zig 0.14.1
zig build run
```

resulting `out.wasm` will be written, localhost the root, open `index.html` and check Javascript Console.

---

## TODO

- A better analyzer/type-checker
- Different int/float type of different signedness and size
- Arrays
- Tuples?
- JS FFI and bind WebGPU
- Proper Erroring (get as many as error possible before quitting + better error messages)

### Analyzer

- No Variable shadowing
- No implicit conversion
- No type-change of variable after declared
- Type inference

### WASM

- Remove hardcoding of some of wasm code-gen
- `var x: float = 5;` interpret 5 as integer, so generated wasm code assignmet doesn't work.

## FUTURE TODO

- Suggest related variable names, for example, programmer types `x_ids` but only `x_idx` exist, so it will suggest `x_idx`.

## Immediate Plan

- Be able to draw triangle on webpage with webgpu.

## Future Plan

1. Be able to parse all the basics feature a programming language can have. (functions, arrays, loops, etc)
2. Design custom IR
3. Use this IR to codegen WASM code
4. Do optimization on custom IR to produce efficient builds.

# WASM

- [Spec](https://webassembly.github.io/spec/core/)
- [Part-1](https://coinexsmartchain.medium.com/wasm-introduction-part-1-binary-format-57895d851580)
- [Part-2](https://coinexsmartchain.medium.com/wasm-introduction-part-2-instruction-set-operand-stack-38e5171b52e6)
- [Part-3](https://coinexsmartchain.medium.com/wasm-introduction-part-3-memory-7426f19c9624)
- [Part-4](https://coinexsmartchain.medium.com/wasm-introduction-part-4-function-call-9ddf62272f15)
- [Part-5](https://coinexsmartchain.medium.com/wasm-introduction-part-5-control-instructions-1cc21a180618)
- [Part-6](https://coinexsmartchain.medium.com/wasm-introduction-part-6-table-indirect-call-65ad0404b003)
- [Part-7](https://coinexsmartchain.medium.com/wasm-introduction-part-7-text-format-2d608e50daab)
