
# TODO

- Implement parser for function parameters and function return type
- Implement WASM codegen for function parameters and return
- Implement parser and WASM codegen for branches
- Implement parser and WASM codegen for loops

## Bugs in compiler

1.
```
var x: float = 5;// generate x it as int and not float
```
PARSER: The 5 is parsed as int instead of float

2.
```
print(z/2.0); // this doesn't work (give false negative) ;(
```
IDK: Gives this error
```
thread 245479 panic: index out of bounds: index 2143289344, len 0
/--/--/Khichu/src/wasm/codegen.zig:264:56: 0x10040a6e7 in generateWASMCodeFromAst (UndefinedLanguage)
            const expr_type = ExprTypeTable.table.items[ast.nodes.items[node_idx].idx].type;
```

3.

This doesn't work (it should):

```
fn foo() float {
    return 32.0;
}

fn main() void {
    print(foo());
}
```

This works (as it should):

```
fn foo() float {
    return 32.0;
}

fn main() void {
    var x: float = foo();
    print(x);
}
```

NOTE: Calling function in function arguments now works, but calling function in print() doesn't because it is not a real function.
TODO: Make print() a real function, by introducting some sort of foreign object concepts (able to export/import functions/variables)
