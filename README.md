# UndefinedLanguage

## TODO

- Add some tests running facility
- Disallow variable shadowing
- Check if code-gen for assignment statement/expression is good or not.
- Add and check var decal. and assignment for other types.
- Add back semantic analyzer.
- Turn current VM to register base.
- Add backend for WASM.
- Find some way to collect as many as errors possible before quitting.
- Allow 'var x = 5;', that is allow type inference.
- What should be better error message?
```
test.ul:0: Expected ';' after 'expression', found 'identifier'.
x: float = 8.2 + 2.1 / 3.8;
^--------------------------
```

# WASM
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
zig build run
```
