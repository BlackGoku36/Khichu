#ifndef vm_h
#define vm_h

#include "chunk.h"
#include "value.h"

#define MAX_STACK 256

typedef enum{
	OK, COMP_TIME_ERROR, RUN_TIME_ERROR
}vm_error;

typedef struct{
	chunk* chunk;
	value stack[MAX_STACK];
	uint32_t stack_index;
} virtual_machine;

void init_vm();
void free_vm();
uint8_t read_instruction(uint8_t* ip);
void push(value value);
value pop();
vm_error interpret(chunk* chunk);

#endif
