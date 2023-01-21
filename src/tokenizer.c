#include "tokenizer.h"
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <math.h>

#define TOKEN_POOL_SIZE 1000

char peek(char* source, ScannerStatus scan_status){
	return source[scan_status.current];
}

char consume(char* source, ScannerStatus* scan_status){
	return source[scan_status->current++];
}

void produce_token(TokenPool* pool, enum TokenType type, uint64_t val){
	pool->pool[pool->cursor] = (Token){.type = type, .val = val};
	pool->cursor += 1;
}

bool is_digit(char c){
	return c >= '0' && c <= '9';
}

uint64_t get_number(char* source, ScannerStatus* scan_status){
	uint32_t start = scan_status->start;
	while (is_digit(peek(source, *scan_status))) {
		consume(source, scan_status);
	}
	uint64_t number = 0;
	for (uint32_t i = scan_status->current; i > start; i--) {
		number += (source[i-1]-48) * (uint64_t) pow(10, scan_status->current-i);
	}
	return number;
}

TokenPool scanner(char* source, uint32_t len){
	ScannerStatus scan_status = {};
	
	TokenPool token_pool = {};
	token_pool.pool = calloc(TOKEN_POOL_SIZE, sizeof(Token));
	
	while (scan_status.current < len) {
		scan_status.start = scan_status.current;
		char c = consume(source, &scan_status);
		switch (c) {
			case '+': produce_token(&token_pool, PLUS, 0); break;
			case '-': produce_token(&token_pool, MINUS, 0); break;
			case '*': produce_token(&token_pool, STAR, 0); break;
			case '/': produce_token(&token_pool, SLASH, 0); break;
			// case ':': produce_token(&token_pool, COLON, 0); break;
			case '(': produce_token(&token_pool, LEFT_PAREN, 0); break;
			case ')': produce_token(&token_pool, RIGHT_PAREN, 0); break;
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
					produce_token(&token_pool, INT_64, get_number(source, &scan_status));
				}else{
					printf("Unexpected character %c at line %d\n", c, scan_status.line);
				}
		}
	}
	produce_token(&token_pool, EOF, 0);
	return token_pool;
}