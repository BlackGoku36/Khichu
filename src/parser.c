#include <stdint.h>
#include <stdlib.h>
#include <assert.h>
#include <stdbool.h>
#include <stdio.h>

#include "parser.h"
#include "chunk.h"
#include "value.h"

token* tokens;
char* source;
chunk* compiling_chunk;

void parser_report_error(char* source, uint32_t from, uint32_t to, const char* message, bool panic){
	uint32_t i = 0;
	uint32_t line = 0;
	uint32_t line_start = 0;
	while (source[i] != '\0') {
		if(i == from) break;
		if(source[i] == '\n'){
			line += 1;
			line_start = i;
		}
		i += 1;
	}
	printf("Error at line: %d, %s\n", line, message);
	uint32_t j = line_start;
	while (source[j] != '\n' && source[j] != '\0') {
		printf("%c", source[j]);
		j += 1;
	}
	printf("\n");
	j = line_start;
	while (source[j] != '\n' && source[j] != '\0') {
		if(j >= from && j <= to - 1){
			printf("^");
		}else{
			printf("-");
		}
		j += 1;
	}
	printf("\n");
	if(panic) exit(EXIT_FAILURE);
}


ast_node* make_ast_node(op_enum op, ast_node* left, ast_node* right, value val){
	ast_node* node = (ast_node*) malloc(sizeof(ast_node));
	assert(node != NULL);
	node->op = op;
	node->left = left;
	node->right = right;
	node->val = val;
	return node;
}

ast_node* make_leaf_node(op_enum op, value val){
	return make_ast_node(op, NULL, NULL, val);
}

ast_node* make_unary_node(op_enum op, ast_node* node, value val){
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

void parser_match_consume(parser_status* ps, token_type tok, const char* error, token error_at){
	if(match(*ps, tok)){
		parser_consume(ps);
	}else{
		parser_report_error(source, error_at.loc_start, error_at.loc_end, error, false);
	}
}

int32_t parse_int(char* source, uint32_t from, uint32_t to){
    int32_t result = 0;
    for(uint32_t i = from; i < to; i++){
        result = result * 10 + (source[i] - '0');
    }
    return result;
}

float parse_float(char* source, uint32_t from, uint32_t to){
	float result = 0.0;
	uint32_t i = from;
	while (source[i] != '.') {
		result = result * 10 + (source[i] - '0');
		i += 1;
	}
    float power = 10;
    for(uint32_t j = i+1; j < to; j++){
        result += ((float) (source[j] - '0')) / power;
        power *= 10;
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
	if(match(*parser_status, INT)){
		parser_consume(parser_status);
		token int_token = prev(*parser_status);
		int32_t integer = parse_int(source, int_token.loc_start, int_token.loc_end);
		return make_leaf_node(INT_LIT, (value){.type = INT_VAL, .as.int_number = integer});
	}
	if(match(*parser_status, FLOAT)){
		parser_consume(parser_status);
		token float_token = prev(*parser_status);
		float float_num = parse_float(source, float_token.loc_start, float_token.loc_end);
		return make_leaf_node(FLOAT_LIT, (value){.type = FLOAT_VAL, .as.float_number = float_num});
	}
	if(match(*parser_status, LEFT_PAREN)){
		uint32_t pos = parser_status->current;
		parser_consume(parser_status);
		ast_node* expr = expression(parser_status);
		parser_match_consume(parser_status, RIGHT_PAREN, "Expected ')' after expression", tokens[pos]);
		return expr;
	}

	token current = parser_peek(*parser_status);
	parser_report_error(source, current.loc_start, current.loc_end, "Unknow literal found!", true);

	return NULL; // Unreachable
}

ast_node* unary(parser_status* parser_status){
	// TODO: ADD '!' support
	if(match(*parser_status, MINUS)){
		parser_consume(parser_status);
		ast_node* right = unary(parser_status);
		return make_unary_node(NEGATE, right, (value){});
	}
	return primary(parser_status);
}

ast_node* factor(parser_status* parser_status){
	ast_node* left = unary(parser_status);

	while(match2(*parser_status, STAR, SLASH)){
		parser_consume(parser_status);
		op_enum op = get_operator(prev(*parser_status).type);
		ast_node* right = unary(parser_status);
		left = make_ast_node(op, left, right, (value){});
	}
	return left;
}

ast_node* term(parser_status* parser_status){
	ast_node* left = factor(parser_status);

	while(match2(*parser_status, PLUS, MINUS)){
		parser_consume(parser_status);
		op_enum op = get_operator(prev(*parser_status).type);
		ast_node* right = factor(parser_status);
		left = make_ast_node(op, left, right, (value){});
	}
	return left;
}

ast_node* expression(parser_status* parser_status){
	return term(parser_status);
}

chunk* current_chunk(){
	return compiling_chunk;
}

void emit_bytecode(uint8_t byte){
	write_chunk(current_chunk(), byte);
}

void emit_bytecode2(uint8_t byte1, uint8_t byte2){
	emit_bytecode(byte1);
	emit_bytecode(byte2);
}

void end_parser(){
	write_chunk(current_chunk(), OP_RETURN);
}

void analysis(ast_node* node){
	if(node->left){
		analysis(node->left);
	}
	if(node->right){
		analysis(node->right);
	}

	switch (node->op) {
		case ADD:
		case SUB:
		case MULT:
		case DIV:{
			if(node->left->val.type != node->right->val.type){
				printf("Type miss-match between: ");
				switch (node->left->val.type) {
					case INT_VAL: printf("%d (INT)", node->left->val.as.int_number); break;
					case FLOAT_VAL: printf("%f (FLOAT)", node->left->val.as.float_number); break;
					case BOOL_VAL: printf("%d (BOOL)", node->left->val.as.boolean); break;
				}
				printf(" and ");
				switch (node->right->val.type) {
					case INT_VAL: printf("%d (INT)", node->right->val.as.int_number); break;
					case FLOAT_VAL: printf("%f (FLOAT)", node->right->val.as.float_number); break;
					case BOOL_VAL: printf("%d (BOOL)", node->right->val.as.boolean); break;
				}
				printf("\n");
				exit(EXIT_FAILURE);
			}
		}
		default:;
	}
}

void code_gen(ast_node* node){
	uint32_t right_val = 0;
	uint32_t left_val = 0;

	if(node->left){
		code_gen(node->left);
	}

	if(node->right){
		code_gen(node->right);
	}

	switch (node->op) {
		case NEGATE:{
			emit_bytecode(OP_NEGATE);
			break;
		}
	    case ADD:{
			emit_bytecode(OP_ADD);
			break;
		}
	    case SUB:{
			emit_bytecode(OP_SUB);
			break;
		}
	    case MULT:{
			emit_bytecode(OP_MULT);
			break;
		}
	    case DIV:{
			emit_bytecode(OP_DIV);
			break;
		}
	    case INT_LIT:
		case FLOAT_LIT:{
			emit_bytecode2(OP_CONSTANT, add_constant(current_chunk(), node->val));
			break;
		}
	    default:
	      printf("Unknown AST operator %d\n", node->op);
	      exit(1);
	  }
}

void parse(token_pool* toks, char* code, chunk* chunk){
	tokens = toks->pool;
	source = code;
	compiling_chunk = chunk;
	parser_status parser_status = {};

	ast_node* start = expression(&parser_status);
	parser_match_consume(&parser_status, END_OF_FILE, "Expected end of expression", parser_peek(parser_status));
	analysis(start);
	code_gen(start);
	end_parser();
}
