#ifndef parser_h
#define parser_h

#include "tokenizer.h"
#include "chunk.h"
#include "value.h"
#include "stdio.h"
#include <stdlib.h>

typedef struct{
	uint32_t current;
}parser_status;

typedef enum op_enum{
	NEGATE, ADD, SUB, MULT, DIV, INT_LIT, FLOAT_LIT, BOOL_LIT,
	NOT, GREATER, LESSER, GREATER_EQUAL, LESSER_EQUAL, EQUAL_EQUAL, NOT_EQUAL
}op_enum;

typedef struct ast_node{
	struct ast_node* left;
	struct ast_node* right;
	op_enum op;
	value val;
	loc_info loc;
} ast_node;

void parse(token_pool* toks, char* code, chunk* chunk);
ast_node* expression(parser_status* parser_status);

#endif
