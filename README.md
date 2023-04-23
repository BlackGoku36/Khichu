# UndefinedLanguage

## TODO

- Add error handling (including line number, runtime/compile time)
- Errors:
	- When integer/float are calculated with each other
- Keep in mind about brackets mis-match
- Implement boolean operations: ==, !=, >=, <=, !x

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
