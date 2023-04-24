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

void calculate_line(char* source, loc_info loc, uint32_t* line, uint32_t* line_start){
	uint32_t i = 0;
	while (source[i] != '\0') {
		if(i == loc.start) break;
		if(source[i] == '\n'){
			*line += 1;
			*line_start = i;
		}
		i += 1;
	}
}

void print_line(char* source, uint32_t line_start){
	uint32_t j = line_start;
	while (source[j] != '\n' && source[j] != '\0') {
		printf("%c", source[j]);
		j += 1;
	}
	printf("\n");
}

void parser_report_error(char* source, loc_info loc, const char* message, bool panic){
	uint32_t line = 0;
	uint32_t line_start = 0;
	calculate_line(source, loc, &line, &line_start);
	printf("Error at line: %d, %s\n", line, message);
	print_line(source, line_start);
	uint32_t j = line_start;
	while (source[j] != '\n' && source[j] != '\0') {
		if(j >= loc.start && j <= loc.end - 1){
			printf("^");
		}else{
			printf("-");
		}
		j += 1;
	}
	printf("\n");
	if(panic) exit(EXIT_FAILURE);
}

void parser_report_error2(char* source, loc_info loc1, loc_info loc2, const char* message, bool panic){
	uint32_t line = 0;
	uint32_t line_start = 0;
	calculate_line(source, loc1, &line, &line_start);
	printf("Error at line: %d, %s\n", line, message);
	print_line(source, line_start);
	uint32_t j = line_start;
	while (source[j] != '\n' && source[j] != '\0') {
		if((j >= loc1.start && j <= loc1.end - 1) || (j >= loc2.start && j <= loc2.end - 1)){
			printf("^");
		}else{
			printf("-");
		}
		j += 1;
	}
	printf("\n");
	if(panic) exit(EXIT_FAILURE);
}


ast_node* make_ast_node(op_enum op, ast_node* left, ast_node* right, value val, loc_info loc){
	ast_node* node = (ast_node*) malloc(sizeof(ast_node));
	assert(node != NULL);
	node->op = op;
	node->left = left;
	node->right = right;
	node->val = val;
	node->loc = loc;
	return node;
}

ast_node* make_leaf_node(op_enum op, value val, loc_info loc){
	return make_ast_node(op, NULL, NULL, val, loc);
}

ast_node* make_unary_node(op_enum op, ast_node* node, value val, loc_info loc){
	return make_ast_node(op, node, NULL, val, loc);
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
		parser_report_error(source, error_at.loc, error, true);
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
	// Calculate left side of '.'
	uint32_t i = from;
	while (source[i] != '.') {
		result = result * 10 + (source[i] - '0');
		i += 1;
	}
	// Calculate right side of '.'
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
		int32_t integer = parse_int(source, int_token.loc.start, int_token.loc.end);
		return make_leaf_node(INT_LIT, INT_VALUE(integer), int_token.loc);
	}
	if(match(*parser_status, FLOAT)){
		parser_consume(parser_status);
		token float_token = prev(*parser_status);
		float float_num = parse_float(source, float_token.loc.start, float_token.loc.end);
		return make_leaf_node(FLOAT_LIT, FLOAT_VALUE(float_num), float_token.loc);
	}
	if(match(*parser_status, LEFT_PAREN)){
		uint32_t pos = parser_status->current;
		parser_consume(parser_status);
		ast_node* expr = expression(parser_status);
		parser_match_consume(parser_status, RIGHT_PAREN, "Expected ')' after expression", tokens[pos]);
		return expr;
	}

	token current = parser_peek(*parser_status);
	parser_report_error(source, current.loc, "Unknow literal found!", true);

	return NULL; // Unreachable
}

ast_node* unary(parser_status* parser_status){
	// TODO: ADD '!' support
	if(match(*parser_status, MINUS)){
		token minus_token = tokens[parser_status->current];
		parser_consume(parser_status);
		ast_node* right = unary(parser_status);
		return make_unary_node(NEGATE, right, (value){.type = right->val.type}, (loc_info){.start= minus_token.loc.start, .end=right->loc.end});
	}
	return primary(parser_status);
}

ast_node* factor(parser_status* parser_status){
	ast_node* left = unary(parser_status);

	while(match2(*parser_status, STAR, SLASH)){
		parser_consume(parser_status);
		op_enum op = get_operator(prev(*parser_status).type);
		ast_node* right = unary(parser_status);
		left = make_ast_node(op, left, right, (value){.type = right->val.type}, (loc_info){.start=left->loc.start, .end=right->loc.end});
	}
	return left;
}

ast_node* term(parser_status* parser_status){
	ast_node* left = factor(parser_status);

	while(match2(*parser_status, PLUS, MINUS)){
		parser_consume(parser_status);
		op_enum op = get_operator(prev(*parser_status).type);
		ast_node* right = factor(parser_status);
		left = make_ast_node(op, left, right, (value){.type = right->val.type}, (loc_info){.start=left->loc.start, .end=right->loc.end});
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
			if(GET_TYPE(node->left->val) != GET_TYPE(node->right->val)){
				parser_report_error2(source, node->left->loc, node->right->loc, "Type miss-match", false);
				const char* op_type;
				if(node->op == ADD) op_type = "added";
				else if(node->op == SUB) op_type = "substracted";
				else if(node->op == MULT) op_type = "multiplied";
				else if(node->op == DIV) op_type = "divided";
				printf("Type %s and %s can't be %s\n", type_str(node->left->val), type_str(node->right->val), op_type);
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
