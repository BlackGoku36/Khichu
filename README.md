# UndefinedLanguage

## TODO

- Implement boolean operations: ==, !=, >=, <=, !x
- Implement strings (formating), to improve error messages.
- Implement stack trace for debugging purpose (there was some zig trick to get this)
- Fix `illegal hardware instruction` error when running `23 / 29 + 12 * (34.0 - 54.0) - 65 * 45 + 2`
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
