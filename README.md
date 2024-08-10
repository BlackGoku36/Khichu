# Khichu

[Khichu](https://en.wikipedia.org/wiki/Khichu) is experimental programming language that targets WASM and a custom register-based VM.

## TODO

- Add some tests running facility
- Check if code-gen for assignment statement/expression is good or not.
- Find some way to collect as many as errors possible before quitting.
- Allow 'var x = 5;', that is allow type inference.
- Analyzer
    - Check if the identifier used already exists or not.
        - Turn symbol table into hashmap.
        - While reporting error, show where previous identifier is declared.
        - Maybe do this in semantic analyzer?
    - Disallow variable shadowing.
    - Disallow changing type on assignment to same variable (if var is float, then it is legal right now to assign bool to it, but it should be illegal).
- Minor refactor:
    - Code is bit stinky
- What should be better error message?
```
test.ul:0: Expected ';' after 'expression', found 'identifier'.
x: float = 8.2 + 2.1 / 3.8;
^--------------------------
```

### Language
- Add functions, conditioanls and loops
- Add data types such as different signedness of integer with different size, arrays, etc.

### WASM
- Remove hardcoding of some of wasm code-gen
- `var x: float = 5;` interpret 5 as integer, so generated wasm code assignmet doesn't work.

### VM
- Start Register-Based VM

## FUTURE TODO
- Suggest related variable names, for example, programmer types `x_ids` but only `x_idx` exist, so it will suggest `x_idx`.

# WASM

- [Spec](https://webassembly.github.io/spec/core/)
- [Part-1](https://coinexsmartchain.medium.com/wasm-introduction-part-1-binary-format-57895d851580)
- [Part-2](https://coinexsmartchain.medium.com/wasm-introduction-part-2-instruction-set-operand-stack-38e5171b52e6)
- [Part-3](https://coinexsmartchain.medium.com/wasm-introduction-part-3-memory-7426f19c9624)
- [Part-4](https://coinexsmartchain.medium.com/wasm-introduction-part-4-function-call-9ddf62272f15)
- [Part-5](https://coinexsmartchain.medium.com/wasm-introduction-part-5-control-instructions-1cc21a180618)
- [Part-6](https://coinexsmartchain.medium.com/wasm-introduction-part-6-table-indirect-call-65ad0404b003)
- [Part-7](https://coinexsmartchain.medium.com/wasm-introduction-part-7-text-format-2d608e50daab)

## Compile and Run

Write the code in `test.ul` and do:

```
# Zig 0.13
zig build run
```

## Plan

1. Be able to parse all the basics feature a programming language can have. (functions, arrays, loops, etc)
2. Write WASM code gen for it
3. Design custom IR
4. Use this IR to codegen WASM code
5. Design register-based VM and it's bytecode.
6. Do optimization on custom IR to produce efficient builds.
7. Maybe do RISC-V codegen
