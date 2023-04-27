#ifndef chunk_h
#define chunk_h

#include <stdint.h>
#include "value.h"

typedef enum {
	OP_RETURN, OP_CONSTANT, OP_NEGATE,
	OP_ADD, OP_SUB, OP_MULT, OP_DIV,
	OP_TRUE, OP_FALSE, OP_NOT, OP_GREATER, OP_LESSER, OP_GREATER_EQUAL, OP_LESSER_EQUAL
}op_code;

typedef struct{
	uint32_t len;
	uint32_t capacity;
	uint8_t* code;
	value_array constants;
} chunk;

chunk init_chunk();
void resize_chunk(chunk* chunk, uint32_t new_capacity);
void write_chunk(chunk* chunk, uint8_t op_code);
void deinit_chunk(chunk* chunk);

uint32_t add_constant(chunk* chunk, value val);

uint32_t print_op_code(chunk* chunk, uint32_t offset);
void print_chunk(chunk* chunk, char* label);

#endif
