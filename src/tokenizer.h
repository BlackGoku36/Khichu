#ifndef tokenizer_h
#define tokenizer_h

#include <stdint.h>

typedef enum token_type{
	TOK_INT, TOK_FLOAT,
	TOK_STRING,
	TOK_PLUS, TOK_MINUS, TOK_STAR, TOK_SLASH, TOK_NOT,
	TOK_EQUAL, TOK_LESSER, TOK_GREATER,
	TOK_LESSER_LESSER, TOK_GREATER_GREATER,
	TOK_EQUAL_EQUAL, TOK_LESSER_EQUAL, TOK_GREATER_EQUAL,
	TOK_PLUS_EQUAL, TOK_MINUS_EQUAL, TOK_STAR_EQUAL, TOK_SLASH_EQUAL,
	TOK_COLON, TOK_SEMICOLON, TOK_DOT, TOK_COMMA,
	TOK_LEFT_PAREN, TOK_RIGHT_PAREN, TOK_LEFT_BRACE, TOK_RIGHT_BRACE, TOK_LEFT_BRACKET, TOK_RIGHT_BRACKET,
	TOK_IDENTIFIER,
	TOK_LET, TOK_CONST, TOK_STRUCT, TOK_FN, TOK_IF, TOK_ELSE, TOK_FOR, TOK_WHILE,
	TOK_U8, TOK_U16, TOK_U32, TOK_U64, TOK_I8, TOK_I16, TOK_I32, TOK_I64, TOK_F32, TOK_F64, TOK_TRUE, TOK_FALSE, TOK_BOOL,
	TOK_END_OF_FILE,
}token_type;

typedef struct{
	uint32_t start;
	uint32_t end;
}loc_info;

typedef struct{
	token_type type;
	loc_info loc;
}token;

typedef struct{
	token* pool;
	uint32_t cursor;
}token_pool;

typedef struct{
	uint32_t start;
	uint32_t current;
	uint32_t line;
}scanner_status;

void print_token(char* source, token token);
token_pool scanner(char* source, uint32_t len);

#endif
