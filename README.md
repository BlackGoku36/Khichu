# UndefinedLanguage

## TODO

- Implement boolean operations: ==, !=, >=, <=, !x
- Implement strings (formating), to improve error messages.

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
