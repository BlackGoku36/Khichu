#ifndef chunk_h
#define chunk_h

#include <stdint.h>

typedef enum {
	OP_RETURN
}op_code;

typedef struct{
	uint32_t len;
	uint32_t capacity;
	uint8_t* code;
} chunk;

chunk init_chunk();
void resize_chunk(chunk* chunk, uint32_t new_capacity);
void write_chunk(chunk* chunk, uint8_t op_code);
void deinit_chunk(chunk* chunk);

void print_op_code(uint8_t op_code);
void print_chunk(chunk* chunk, char* label);

#endif
