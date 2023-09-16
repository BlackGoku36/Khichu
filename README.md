# UndefinedLanguage

## TODO

- Add some tests running facility
- Check if code-gen for assignment statement/expression is good or not.
- Turn current VM to register base.
- Add backend for WASM.
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
    - Separate analyzer from parser file.
    - Put current code-gen and vm into it own folder.
    - Create new folder for wasm codegen.
- What should be better error message?
```
test.ul:0: Expected ';' after 'expression', found 'identifier'.
x: float = 8.2 + 2.1 / 3.8;
^--------------------------
```

## FUTURE TODO
- Suggest related variable names, for example, programmer uses `x_ids` but only `x_idx` exist, so it will suggest `x_idx`.

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
