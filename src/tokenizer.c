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
		"PLUS", "MINUS", "STAR", "SLASH", "NOT",
		"AMP", "AMP_AMP", "PIPE", "PIPE_PIPE",
		"EQUAL", "LESSER", "GREATER",
		"LESSER_LESSER", "GREATER_GREATER",
		"EQUAL_EQUAL", "NOT_EQUAL", "LESSER_EQUAL", "GREATER_EQUAL",
		"PLUS_EQUAL", "MINUS_EQUAL", "STAR_EQUAL", "SLASH_EQUAL",
		"COLON", "SEMICOLON", "DOT", "COMMA",
		"LEFT_PAREN", "RIGHT_PAREN", "LEFT_BRACE", "RIGHT_BRACE", "LEFT_BRACKET", "RIGHT_BRACKET",
		"IDENTIFIER",
		"LET", "CONST", "STRUCT", "FN", "IF", "ELSE", "FOR", "WHILE",
		"U8", "U16", "U32", "U64", "I8", "I16", "I32", "I64", "F32", "F64", "TRUE", "FALSE", "BOOL",
		"END_OF_FILE",
	};
	printf("Token, type: %s, str:", token_str[token.type]);
	for (uint32_t i = token.loc.start; i < token.loc.end; i++) {
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
	pool->pool[pool->cursor] = (token){.type = type, .loc.start = loc_start, .loc.end = loc_end};
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
	printf("Error at line: %d, %s\n", line, message);
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
		"u8", "u16", "u32", "u64", "i8", "i16", "i32", "i64", "f32", "f64", "true", "false", "bool"
	};
	const token_type key_tok[] = {
		TOK_LET, TOK_CONST, TOK_STRUCT, TOK_FN, TOK_IF, TOK_ELSE, TOK_FOR, TOK_WHILE,
		TOK_U8, TOK_U16, TOK_U32, TOK_U64, TOK_I8, TOK_I16, TOK_I32, TOK_I64, TOK_F32, TOK_F64, TOK_TRUE, TOK_FALSE, TOK_BOOL
	};

	while (is_alpha_numeric(peek(source, *scan_status))) {
		consume(source, scan_status);
	}

	*type = TOK_IDENTIFIER;
	for (uint32_t i = 0; i < 21; i++) {
		bool found = match_string(source, key_str[i], scan_status->start, scan_status->current);
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
				token_type type = match_consume(source, &scan_status, '=') ? TOK_PLUS_EQUAL : TOK_PLUS;
				produce_token(&token_pool, type, scan_status.start, scan_status.current);
				break;
			}
			case '-': {
				token_type type = match_consume(source, &scan_status, '=') ? TOK_MINUS_EQUAL : TOK_MINUS;
				produce_token(&token_pool, type, scan_status.start, scan_status.current);
				break;
			}
			case '*': {
				token_type type = match_consume(source, &scan_status, '=') ? TOK_STAR_EQUAL : TOK_STAR;
				produce_token(&token_pool, type, scan_status.start, scan_status.current);
				break;
			}
			case '/': {
				token_type type = match_consume(source, &scan_status, '=') ? TOK_SLASH_EQUAL : TOK_SLASH;
				if(type == TOK_SLASH && match_consume(source, &scan_status, '/')){
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
				token_type type = match_consume(source, &scan_status, '=') ? TOK_EQUAL_EQUAL : TOK_EQUAL;
				produce_token(&token_pool, type, scan_status.start, scan_status.current);
				break;
			}
			case '<': {
				token_type type = match_consume(source, &scan_status, '=') ? TOK_LESSER_EQUAL : TOK_LESSER;
				if(type == TOK_LESSER) type = match_consume(source, &scan_status, '<') ? TOK_LESSER_LESSER : TOK_LESSER;
				produce_token(&token_pool, type, scan_status.start, scan_status.current);
				break;
			}
			case '>': {
				token_type type = match_consume(source, &scan_status, '=') ? TOK_GREATER_EQUAL : TOK_GREATER;
				if(type == TOK_GREATER) type = match_consume(source, &scan_status, '>') ? TOK_GREATER_GREATER : TOK_GREATER;
				produce_token(&token_pool, type, scan_status.start, scan_status.current);
				break;
			}
			case ':': produce_token(&token_pool, TOK_COLON, scan_status.start, scan_status.current); break;
			case '(': produce_token(&token_pool, TOK_LEFT_PAREN, scan_status.start, scan_status.current); break;
			case ')': produce_token(&token_pool, TOK_RIGHT_PAREN, scan_status.start, scan_status.current); break;
			case '{': produce_token(&token_pool, TOK_LEFT_BRACE, scan_status.start, scan_status.current); break;
			case '}': produce_token(&token_pool, TOK_RIGHT_BRACE, scan_status.start, scan_status.current); break;
			case '[': produce_token(&token_pool, TOK_LEFT_BRACKET, scan_status.start, scan_status.current); break;
			case ']': produce_token(&token_pool, TOK_RIGHT_BRACKET, scan_status.start, scan_status.current); break;
			case '.': produce_token(&token_pool, TOK_DOT, scan_status.start, scan_status.current); break;
			case ';': produce_token(&token_pool, TOK_SEMICOLON, scan_status.start, scan_status.current); break;
			case ',': produce_token(&token_pool, TOK_COMMA, scan_status.start, scan_status.current); break;
			case '"':{
				uint32_t loc_end = parse_string(source, &scan_status);
				produce_token(&token_pool, TOK_STRING, scan_status.start+1, loc_end-1);
				break;
			}
			case '!':{
				token_type type = match_consume(source, &scan_status, '=') ? TOK_NOT_EQUAL : TOK_NOT;
				produce_token(&token_pool, type, scan_status.start, scan_status.current); break;
			}
			case '&':{
				token_type type = match_consume(source, &scan_status, '&') ? TOK_AMP_AMP : TOK_AMP;
				produce_token(&token_pool, type, scan_status.start, scan_status.current); break;
			}
			case '|':{
				token_type type = match_consume(source, &scan_status, '|') ? TOK_PIPE_PIPE : TOK_PIPE;
				produce_token(&token_pool, type, scan_status.start, scan_status.current); break;
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
						produce_token(&token_pool, TOK_FLOAT, scan_status.start, toc_end);
					}else{
						produce_token(&token_pool, TOK_INT, scan_status.start, toc_end);
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
	produce_token(&token_pool, TOK_END_OF_FILE, scan_status.start, 0);
	return token_pool;
}
