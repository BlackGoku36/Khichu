#include <stdint.h>
#include <stdlib.h>
#include <assert.h>
#include <stdbool.h>
#include <stdio.h>

#include "parser.h"

token* tokens;
char* source;

ast_node* make_ast_node(op_enum op, ast_node* left, ast_node* right, uint32_t val){
	ast_node* node = (ast_node*) malloc(sizeof(ast_node));
	assert(node != NULL);
	node->op = op;
	node->left = left;
	node->right = right;
	node->val = val;
	return node;
}

ast_node* make_leaf_node(op_enum op, uint32_t val){
	return make_ast_node(op, NULL, NULL, val);
}

ast_node* make_unary_node(op_enum op, ast_node* node, uint32_t val){
	return make_ast_node(op, node, NULL, val);
}

token parser_peek(parser_status ps){
	return tokens[ps.current];
}

token prev(parser_status ps){
	return tokens[ps.current - 1];
}

bool match(parser_status ps, token_type token_type){
	return parser_peek(ps).type == token_type;
}

bool match2(parser_status ps, token_type token1, token_type token2){
	token_type curr = parser_peek(ps).type;
	return curr == token1 || curr == token2;
}

token parser_consume(parser_status* ps){
	token tok = tokens[ps->current];
	ps->current += 1;
	return tok;
}

uint32_t parse_int(char* source, uint32_t from, uint32_t to){
    uint32_t result = 0;
    for(uint32_t i = from; i < to; i++){
    	//TODO: Put check source[i] >= '0' && source[i] <= '9' and return some error
        result = result * 10 + (source[i] - '0');
    }
    return result;
}

op_enum get_operator(token_type type){
	op_enum op = -1;
	switch (type) {
		case PLUS: op = ADD; break;
		case MINUS: op = SUB; break;
		case STAR: op = MULT; break;
		case SLASH: op = DIV; break;
		default:
			printf("Invalid OP type\n");
	}
	return op;
}

ast_node* primary(parser_status* parser_status){
	// TODO: add float parsing
	if(match(*parser_status, INT)){
		parser_consume(parser_status);
		token int_token = prev(*parser_status);
		//TODO: Put some error handling in-case parse_int fail
		printf("int: %d\n", parse_int(source, int_token.loc_start, int_token.loc_end));
		return make_leaf_node(INT_LIT, parse_int(source, int_token.loc_start, int_token.loc_end));
	}else{
		//TODO: Actually do some error handling
		printf("Unknow literal found!\n");
		exit(EXIT_FAILURE);
	}
}

ast_node* unary(parser_status* parser_status){
	// TODO: ADD '!' support
	if(match(*parser_status, MINUS)){
		parser_consume(parser_status);
		// token minus_token = prev(*parser_status);
		ast_node* right = unary(parser_status);
		return make_unary_node(SUB, right, 0);
	}
	return primary(parser_status);
}

ast_node* factor(parser_status* parser_status){
	ast_node* left = unary(parser_status);

	while(match2(*parser_status, STAR, SLASH)){
		parser_consume(parser_status);
		op_enum op = get_operator(prev(*parser_status).type);
		ast_node* right = unary(parser_status);
		left = make_ast_node(op, left, right, 0);
	}
	return left;
}

ast_node* term(parser_status* parser_status){
	ast_node* left = factor(parser_status);

	while(match2(*parser_status, PLUS, MINUS)){
		parser_consume(parser_status);
		op_enum op = get_operator(prev(*parser_status).type);
		ast_node* right = factor(parser_status);
		left = make_ast_node(op, left, right, 0);
	}
	return left;
}

// ast_node* binary(parser_status* parser_status){
// 	ast_node* left = primary(parser_status);

// 	if(parser_peek(*parser_status).type == END_OF_FILE){
// 		return left;
// 	}

// 	token_type type = parser_peek(*parser_status).type;
// 	op_enum op = get_operator(type);

// 	parser_consume(parser_status);

// 	ast_node* right = binary(parser_status);

// 	return make_ast_node(op, left, right, 0);
// }

int interpret_ast(ast_node* node){
	uint32_t right_val = 0;
	uint32_t left_val = 0;

	if(node->left){
		left_val = interpret_ast(node->left);
	}

	if(node->right){
		right_val = interpret_ast(node->right);
	}

	switch (node->op) {
	    case ADD:
	      return (left_val + right_val);
	    case SUB:
	      return (left_val - right_val);
	    case MULT:
	      return (left_val * right_val);
	    case DIV:
	      return (left_val / right_val);
	    case INT_LIT:
	      return (node->val);
	    default:
	      printf("Unknown AST operator %d\n", node->op);
	      exit(1);
	  }
}

void parse(token_pool* toks, char* code){
	tokens = toks->pool;
	source = code;
	parser_status parser_status = {};

	ast_node* start = term(&parser_status);
	printf("%d\n", interpret_ast(start));
}
