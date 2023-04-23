# UndefinedLanguage

## TODO

- Implement boolean operations: ==, !=, >=, <=, !x
- Fix the code to make value useable like generics, instead of copy pasting switch-case like 100s time
- Push source code info like line number and start/end pointer of token in source code.

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
