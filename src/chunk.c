#include "chunk.h"
#include "value.h"
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
		.constants = init_value_array(),
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

uint32_t add_constant(chunk* chunk, value val){
	write_value_array(&chunk->constants, val);
	return chunk->constants.len - 1;
}

void deinit_chunk(chunk* chunk){
	free(chunk->code);
	deinit_value_array(&chunk->constants);
	chunk->len = 0;
	chunk->capacity = 0;
	chunk->code = NULL;
}

uint32_t print_op_code(chunk* chunk, uint32_t offset){
	printf("%04d ", offset);
	op_code op = chunk->code[offset];
	switch (op) {
		case OP_RETURN:{
			printf("OP_RETURN\n");
			return offset + 1;
		}
		case OP_CONSTANT:{
			printf("OP_CONSTANT: ");
			switch (chunk->constants.value[chunk->code[offset + 1]].type) {
				case INT_VAL: printf("%d\n", chunk->constants.value[chunk->code[offset + 1]].as.int_number); break;
				case FLOAT_VAL: printf("%f\n", chunk->constants.value[chunk->code[offset + 1]].as.float_number); break;
				case BOOL_VAL: printf("%d\n", chunk->constants.value[chunk->code[offset + 1]].as.boolean); break;
			}
			return offset + 2;
		}
		case OP_NEGATE:{ printf("OP_NEGATE\n"); return offset + 1;}
		case OP_ADD:{ printf("OP_ADD\n"); return offset + 1;}
		case OP_SUB:{ printf("OP_SUB\n"); return offset + 1;}
		case OP_MULT:{ printf("OP_MULT\n"); return offset + 1;}
		case OP_DIV:{ printf("OP_DIV\n"); return offset + 1;}
		case OP_TRUE:{printf("OP_TRUE\n"); return offset + 1;}
		case OP_FALSE:{printf("OP_FALSE\n"); return offset + 1;}
		case OP_NOT:{printf("OP_NOT\n"); return offset + 1;}
		case OP_GREATER:{printf("OP_GREATER\n"); return offset + 1;}
		case OP_LESSER:{printf("OP_LESSER\n"); return offset + 1;}
		case OP_GREATER_EQUAL:{printf("OP_GREATER_EQUAL\n"); return offset + 1;}
		case OP_LESSER_EQUAL:{printf("OP_LESSER_EQUAL\n"); return offset + 1;}
		case OP_EQUAL_EQUAL:{printf("OP_EQUAL_EQUAL\n"); return offset + 1;}
		case OP_NOT_EQUAL:{printf("OP_NOT_EQUAL\n"); return offset + 1;}
		case OP_AND:{printf("OP_AND\n"); return offset + 1;}
		case OP_OR:{printf("OP_OR\n"); return offset + 1;}
		default:{
			printf("Invalid op code: %d\n", op);
			return offset + 1;
		}
	}
}

void print_chunk(chunk* chunk, char* label){
	printf("\n--- CHUNK: %s ---\n", label);
	for (uint32_t i = 0; i < chunk->len;) {
		i = print_op_code(chunk, i);
	}
}
