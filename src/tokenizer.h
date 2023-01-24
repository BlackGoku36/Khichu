#include <stdint.h>

typedef enum token_type{
	INT_64,
	PLUS, MINUS, STAR, SLASH,
	LEFT_PAREN, RIGHT_PAREN, END_OF_FILE,
}token_type;

typedef struct{
	token_type type;
	uint32_t loc_start;
	uint32_t loc_end;
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