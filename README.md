# UndefinedLanguage

## TODO

- Add float suppport
- Create custom VM

## Compile and Run

Write code in test.ul

```
gcc src/main.c src/tokenizer.c src/parser.c src/chunk.c -Wall -Wextra -Werror -fsanitize=undefined -lm -g
```

```
./a.out
```
