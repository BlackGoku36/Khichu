#include "tokenizer.h"
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <math.h>

#define TOKEN_POOL_SIZE 1000

void print_token(char* source, token token){
	char const* token_str[] = {"INT_64",
	"PLUS", "MINUS", "STAR", "SLASH",
	"LEFT_PAREN", "RIGHT_PAREN",
	"END_OF_FILE"};
	printf("Token, type: %s, str:", token_str[token.type]);
	for (uint32_t i = token.loc_start; i < token.loc_end; i++) {
			printf("%c", source[i]);
	}
	printf("\n");
}

char peek(char* source, scanner_status scan_status){
	return source[scan_status.current];
}

char consume(char* source, scanner_status* scan_status){
	return source[scan_status->current++];
}

void produce_token(token_pool* pool, token_type type, uint32_t loc_start, uint32_t loc_end){
	pool->pool[pool->cursor] = (token){.type = type, .loc_start = loc_start, .loc_end = loc_end};
	pool->cursor += 1;
}

bool is_digit(char c){
	return c >= '0' && c <= '9';
}

uint32_t get_number_str_len(char* source, scanner_status* scan_status){
	while (is_digit(peek(source, *scan_status))) {
		consume(source, scan_status);
	}
	return scan_status->current;
}

void report_error(char* source, uint32_t line, uint32_t at, const char* message){
	printf("Error at line: %d, %s\n", line+1, message);
	uint32_t error_line_offset = 0;
	uint32_t line_counter = 0;
	// Get offset to the line containing error.
	while (source[error_line_offset] != '\0') {
		if(line_counter == line) break;
		if(source[error_line_offset] == '\n') line_counter++;
		error_line_offset += 1;
	}
	// Print the line
	uint32_t i = error_line_offset;
	while (source[i] != '\n' && source[i] != '\0') {
		printf("%c", source[i]);
		i++;
	}
	printf("\n");
	// Print the fancy pointer
	for (uint32_t j = error_line_offset; j < i; j++) {
		if(j == at)
			printf("^");
		else
			printf("-");
	}
	printf("\n");
}

token_pool scanner(char* source, uint32_t len){
	scanner_status scan_status = {};
	
	token_pool token_pool = {};
	token_pool.pool = calloc(TOKEN_POOL_SIZE, sizeof(token));
	
	while (scan_status.current < len) {
		scan_status.start = scan_status.current;
		char c = consume(source, &scan_status);
		switch (c) {
			case '+': produce_token(&token_pool, PLUS, scan_status.start, scan_status.start+1); break;
			case '-': produce_token(&token_pool, MINUS, scan_status.start, scan_status.start+1); break;
			case '*': produce_token(&token_pool, STAR, scan_status.start, scan_status.start+1); break;
			case '/': produce_token(&token_pool, SLASH, scan_status.start, scan_status.start+1); break;
			// case ':': produce_token(&token_pool, COLON, 0); break;
			case '(': produce_token(&token_pool, LEFT_PAREN, scan_status.start, scan_status.start+1); break;
			case ')': produce_token(&token_pool, RIGHT_PAREN, scan_status.start, scan_status.start+1); break;
			// case '{': produce_token(&token_pool, LEFT_BRACE, 0); break;
			// case '}': produce_token(&token_pool, RIGHT_BRACE, 0); break;
			// case '[': produce_token(&token_pool, LEFT_BRACKET, 0); break;
			// case ']': produce_token(&token_pool, RIGHT_BRACKET, 0); break;
			case ' ': break;
			case '\r': break;
			case '\t': break;
			case '\n': scan_status.line++; break;
			default:
				if(is_digit(c)){
					produce_token(&token_pool, INT_64, scan_status.start, get_number_str_len(source, &scan_status));
				}else{
					report_error(source, scan_status.line, scan_status.start, "Unexpected char found.");
				}
		}
	}
	produce_token(&token_pool, END_OF_FILE, scan_status.start, 0);
	return token_pool;
}