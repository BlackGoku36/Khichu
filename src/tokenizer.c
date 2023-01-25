#include "tokenizer.h"
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <math.h>
#include <string.h>

#define TOKEN_POOL_SIZE 1000

void print_token(char* source, token token){
	char const* token_str[] = {
		"INT", "FLOAT",
		"STRING",
		"PLUS", "MINUS", "STAR", "SLASH",
		"EQUAL", "LESSER", "GREATER",
		"LESSER_LESSER", "GREATER_GREATER",
		"EQUAL_EQUAL", "LESSER_EQUAL", "GREATER_EQUAL",
		"PLUS_EQUAL", "MINUS_EQUAL", "STAR_EQUAL", "SLASH_EQUAL",
		"COLON", "SEMICOLON", "DOT", "COMMA",
		"LEFT_PAREN", "RIGHT_PAREN", "LEFT_BRACE", "RIGHT_BRACE", "LEFT_BRACKET", "RIGHT_BRACKET",
		"IDENTIFIER",
		"LET", "CONST", "STRUCT", "FN", "IF", "ELSE", "FOR", "WHILE",
		"U8", "U16", "U32", "U64", "I8", "I16", "I32", "I64", "F32", "F64",
		"END_OF_FILE",
	};
	printf("Token, type: %s, str:", token_str[token.type]);
	for (uint32_t i = token.loc_start; i < token.loc_end; i++) {
			printf("%c", source[i]);
	}
	printf("\n");
}

char peek(char* source, scanner_status scan_status){
	return source[scan_status.current];
}

char peek_next(char* source, scanner_status scan_status){
	return source[scan_status.current + 1];
}

char consume(char* source, scanner_status* scan_status){
	return source[scan_status->current++];
}

bool match_consume(char* source, scanner_status* scan_status, char match){
	if(peek(source, *scan_status) != match) return false;
	consume(source, scan_status);
	return true;
}

void produce_token(token_pool* pool, token_type type, uint32_t loc_start, uint32_t loc_end){
	pool->pool[pool->cursor] = (token){.type = type, .loc_start = loc_start, .loc_end = loc_end};
	pool->cursor += 1;
}

bool is_digit(char c){
	return c >= '0' && c <= '9';
}

bool is_alpha(char c){
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

bool is_alpha_numeric(char c){
	return is_alpha(c) || is_digit(c);
}

uint32_t parse_number(char* source, scanner_status* scan_status, bool* is_float){
	while (is_digit(peek(source, *scan_status))) {
		consume(source, scan_status);
	}
	if(peek(source, *scan_status) == '.' && is_digit(peek_next(source, *scan_status))){
		consume(source, scan_status); // Consume .
		
		*is_float = true;
		while (is_digit(peek(source, *scan_status))) {
			consume(source, scan_status);
		}
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

bool match_string(char* source, char* str1, uint32_t loc_start, uint32_t loc_end){
	uint32_t j = 0;
	if(strlen(str1) != (loc_end-loc_start)) return false;

	for (uint32_t i = loc_start; i < loc_end; i++) {
		if(str1[j] != source[i]) return false;
		j++;
	}
	return true;
}

uint32_t parse_identifier(char* source, scanner_status* scan_status, token_type* type){
	char* key_str[] = {
		"let", "const", "struct", "fn", "if", "else", "for", "while",
		"u8", "u16", "u32", "u64", "i8", "i16", "i32", "i64", "f32", "f64"
	}; 
	const token_type key_tok[] = {
		LET, CONST, STRUCT, FN, IF, ELSE, FOR, WHILE,
		U8, U16, U32, U64, I8, I16, I32, I64, F32, F64,
	};

	while (is_alpha_numeric(peek(source, *scan_status))) {
		consume(source, scan_status);
	}

	*type = IDENTIFIER;
	for (uint32_t i = 0; i < 18; i++) {
		bool found = match_string(source, key_str[0], scan_status->start, scan_status->current);
		if(found){
			*type = key_tok[i];
			break;
		}
	}
	return scan_status->current;
}

uint32_t parse_string(char* source, scanner_status* scan_status){
	uint32_t start = scan_status->start;
	while (peek(source, *scan_status) != '"' && peek(source, *scan_status) != '\0'){
		if(peek(source, *scan_status) == '\n') scan_status->line++;
		consume(source, scan_status);
	}
	if(peek(source, *scan_status) == '\0'){
		report_error(source, scan_status->line, start, "Unterminated String found");
	}
	// Consume the closing '"'.
	consume(source, scan_status);
	return scan_status->current;
}

token_pool scanner(char* source, uint32_t len){
	scanner_status scan_status = {};
	
	token_pool token_pool = {};
	token_pool.pool = calloc(TOKEN_POOL_SIZE, sizeof(token));
	
	while (scan_status.current < len) {
		scan_status.start = scan_status.current;
		char c = consume(source, &scan_status);
		switch (c) {
			case '+': {
				token_type type = match_consume(source, &scan_status, '=') ? PLUS_EQUAL : PLUS;
				produce_token(&token_pool, type, scan_status.start, scan_status.current);
				break;
			}
			case '-': {
				token_type type = match_consume(source, &scan_status, '=') ? MINUS_EQUAL : MINUS;
				produce_token(&token_pool, type, scan_status.start, scan_status.current);
				break;
			}
			case '*': {
				token_type type = match_consume(source, &scan_status, '=') ? STAR_EQUAL : STAR;
				produce_token(&token_pool, type, scan_status.start, scan_status.current);
				break;
			}
			case '/': {
				token_type type = match_consume(source, &scan_status, '=') ? SLASH_EQUAL : SLASH;
				if(type == SLASH && match_consume(source, &scan_status, '/')){
					while (peek(source, scan_status) != '\n' && scan_status.current < len) {
						consume(source, &scan_status);
					}
					break;
				}else{
					produce_token(&token_pool, type, scan_status.start, scan_status.current);
					break;
				}
				break;
			}
			case '=': {
				token_type type = match_consume(source, &scan_status, '=') ? EQUAL_EQUAL : EQUAL;
				produce_token(&token_pool, type, scan_status.start, scan_status.current);
				break;
			}
			case '<': {
				token_type type = match_consume(source, &scan_status, '=') ? LESSER_EQUAL : LESSER;
				if(type == LESSER) type = match_consume(source, &scan_status, '<') ? LESSER_LESSER : LESSER;
				produce_token(&token_pool, type, scan_status.start, scan_status.current);
				break;
			}
			case '>': {
				token_type type = match_consume(source, &scan_status, '=') ? GREATER_EQUAL : GREATER;
				if(type == GREATER) type = match_consume(source, &scan_status, '>') ? GREATER_GREATER : GREATER;
				produce_token(&token_pool, type, scan_status.start, scan_status.current);
				break;
			}
			case ':': produce_token(&token_pool, COLON, scan_status.start, scan_status.current); break;
			case '(': produce_token(&token_pool, LEFT_PAREN, scan_status.start, scan_status.current); break;
			case ')': produce_token(&token_pool, RIGHT_PAREN, scan_status.start, scan_status.current); break;
			case '{': produce_token(&token_pool, LEFT_BRACE, scan_status.start, scan_status.current); break;
			case '}': produce_token(&token_pool, RIGHT_BRACE, scan_status.start, scan_status.current); break;
			case '[': produce_token(&token_pool, LEFT_BRACKET, scan_status.start, scan_status.current); break;
			case ']': produce_token(&token_pool, RIGHT_BRACKET, scan_status.start, scan_status.current); break;
			case '.': produce_token(&token_pool, DOT, scan_status.start, scan_status.current); break;
			case ';': produce_token(&token_pool, SEMICOLON, scan_status.start, scan_status.current); break;
			case ',': produce_token(&token_pool, COMMA, scan_status.start, scan_status.current); break;
			case '"':{
				uint32_t loc_end = parse_string(source, &scan_status);
				produce_token(&token_pool, STRING, scan_status.start, loc_end);
			}
			case ' ': break;
			case '\r': break;
			case '\t': break;
			case '\n': scan_status.line++; break;
			default:
				if(is_digit(c)){
					bool is_float = false;
					uint32_t toc_end = parse_number(source, &scan_status, &is_float);
					if(is_float){
						produce_token(&token_pool, FLOAT, scan_status.start, toc_end);
					}else{
						produce_token(&token_pool, INT, scan_status.start, toc_end);
					}
				}else if(is_alpha(c)){
					token_type type;
					uint32_t toc_end = parse_identifier(source, &scan_status, &type);
					produce_token(&token_pool, type, scan_status.start, toc_end);
				}
				else{
					report_error(source, scan_status.line, scan_status.start, "Unexpected char found.");
				}
		}
	}
	produce_token(&token_pool, END_OF_FILE, scan_status.start, 0);
	return token_pool;
}