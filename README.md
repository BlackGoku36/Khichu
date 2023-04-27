# UndefinedLanguage

## TODO

- False negative on checking bool(s) equality (hint: fix analyser switch-case)
- Should error when analysis (does in VM): `1.0 < 2.0 < 3.0`
- Implement strings (formating), to improve error messages.
- Implement stack trace for debugging purpose (there was some zig trick to get this)
- Add some tests running facility

## Compile and Run

Write code in test.ul

### Using command line

```
gcc src/main.c src/tokenizer.c src/parser.c src/chunk.c src/value.c src/vm.c -Wall -Wextra -Werror -fsanitize=undefined -lm -g
```

```
./a.out
```

### Using zig build system

```
zig build run
```
