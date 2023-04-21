#include "tokenizer.h"

typedef struct{
	uint32_t current;
}parser_status;

token* tokens;
char* source;

typedef enum op_enum{
	ADD, SUB, MULT, DIV, INT_LIT
}op_enum;

typedef struct ast_node{
	struct ast_node* left;
	struct ast_node* right;
	op_enum op;
	uint32_t val;
} ast_node;

void parse(token_pool* toks, char* code);
