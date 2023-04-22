#include "chunk.h"
#include <stdlib.h>
#include <assert.h>
#include <stdio.h>

#define INIT_CAPACITY 20

chunk init_chunk(){
	uint8_t* code = (uint8_t*) malloc(sizeof(uint8_t) * INIT_CAPACITY);
	assert(code != NULL);
	return (chunk){
		.len = 0,
		.capacity = INIT_CAPACITY,
		.code = code,
	};
}

void resize_chunk(chunk* chunk, uint32_t new_capacity){
	assert(new_capacity > 0);
	uint8_t* new_code = (uint8_t*) realloc(chunk->code, new_capacity);
	assert(new_code != NULL);
	chunk->code = new_code;
}

void write_chunk(chunk* chunk, uint8_t op_code){
	if(chunk->len + 1 > chunk->capacity){
		resize_chunk(chunk, chunk->capacity * 2);
	}
	chunk->code[chunk->len] = op_code;
	chunk->len += 1;
}

void deinit_chunk(chunk* chunk){
	free(chunk->code);
	chunk->len = 0;
	chunk->capacity = 0;
	chunk->code = NULL;
}

void print_op_code(uint8_t op_code){
	switch (op_code) {
		case OP_RETURN: printf("%d - OP_RETURN\n", op_code); break;
		default: printf("Invalid op code: %d\n", op_code); break;
	}
}

void print_chunk(chunk* chunk, char* label){
	printf("--- chunk: %s ---\n", label);
	for (uint32_t i = 0; i < chunk->len; i++) {
		print_op_code(chunk->code[i]);
	}
}
