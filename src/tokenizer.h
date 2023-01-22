#include <stdint.h>

typedef enum token_type{
	IDENTIFIER,
	FLOAT_32, FLOAT_64, INT_8, INT_16, INT_32, INT_64, UINT_8, UINT_16, UINT_32, UINT_64,
	PLUS, MINUS, STAR, SLASH,
	NOT, EQUAL, LESSER, GREATER, NOT_EQUAL, LESSER_EQUAL, GREATER_EQUAL, 
	LEFT_PAREN, RIGHT_PAREN, LEFT_BRACE, RIGHT_BRACE, LEFT_BRACKET, RIGHT_BRACKET,
	SEMICOLON, COLON,
	LET,
	EOF,
}token_type;

typedef struct{
	token_type type;
	uint64_t val;
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

token_pool scanner(char* source, uint32_t len);