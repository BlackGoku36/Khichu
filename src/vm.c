#include "vm.h"
#include "value.h"
#include <stdbool.h>
#include <stdio.h>

virtual_machine vm;

void init_vm(){
	vm.stack_index = 0;
}

void free_vm(){

}

uint8_t read_instruction(uint8_t* ip){
	*ip += 1;
	return vm.chunk->code[*ip - 1];
}

void push(value value){
	vm.stack[vm.stack_index] = value;
	vm.stack_index += 1;
}

value pop(){
	vm.stack_index -= 1;
	return vm.stack[vm.stack_index];
}

vm_error interpret(chunk* chunk){
	vm.chunk = chunk;
	uint8_t ip = 0;

	for(;;) {
		uint8_t instruction;
		switch (instruction = read_instruction(&ip)) {
			case OP_RETURN: {
				print_value(pop());
				return OK;
			}
			case OP_CONSTANT: {
				value constant = vm.chunk->constants.value[read_instruction(&ip)];
				push(constant);
				break;
			}
			case OP_TRUE:{
				push(BOOL_VALUE(true));
				break;
			}
			case OP_FALSE:{
				push(BOOL_VALUE(false));
				break;
			}
			case OP_NOT:{
				value boolean = pop();
				AS_BOOL(boolean) = !AS_BOOL(boolean);
				push(boolean);
				break;
			}
			case OP_NEGATE:{
				value val = pop();
				switch (val.type) {
					case INT_VAL: AS_INT(val) = -AS_INT(val); break;
					case FLOAT_VAL: AS_FLOAT(val) = -AS_FLOAT(val); break;
					default:{
						printf("Invalid type for NEGATE operation\n");
						return RUN_TIME_ERROR;
					}
				}
				push(val);
				break;
			}
			case OP_ADD:{
				value b = pop();
				value a = pop();
				switch (a.type) {
					case INT_VAL: AS_INT(a) += AS_INT(b); break;
					case FLOAT_VAL: AS_FLOAT(a) += AS_FLOAT(b); break;
					default:{
						printf("Invalid type for ADD operation\n");
						return RUN_TIME_ERROR;
					}
				}
				push(a);
				break;
			}
			case OP_SUB:{
				value b = pop();
				value a = pop();
				switch (a.type) {
					case INT_VAL: AS_INT(a) -= AS_INT(b); break;
					case FLOAT_VAL: AS_FLOAT(a) -= AS_FLOAT(b); break;
					default:{
						printf("Invalid type for SUB operation\n");
						return RUN_TIME_ERROR;
					}
				}
				push(a);
				break;
			}
			case OP_MULT:{
				value b = pop();
				value a = pop();
				switch (a.type) {
					case INT_VAL: AS_INT(a) *= AS_INT(b); break;
					case FLOAT_VAL: AS_FLOAT(a) *= AS_FLOAT(b); break;
					default:{
						printf("Invalid type for MULT operation\n");
						return RUN_TIME_ERROR;
					}
				}
				push(a);
				break;
			}
			case OP_DIV:{
				value b = pop();
				value a = pop();
				switch (a.type) {
					case INT_VAL: AS_INT(a) /= AS_INT(b); break;
					case FLOAT_VAL: AS_FLOAT(a) /= AS_FLOAT(b); break;
					default:{
						printf("Invalid type for DIV operation\n");
						return RUN_TIME_ERROR;
					}
				}
				push(a);
				break;
			}
			case OP_GREATER:{
				value b = pop();
				value a = pop();
				value c = (value){.type=BOOL_VAL};
				switch (a.type) {
					case INT_VAL: AS_BOOL(c) = AS_INT(a) > AS_INT(b); break;
					case FLOAT_VAL: AS_BOOL(c) = AS_FLOAT(a) > AS_FLOAT(b); break;
					default:{
						printf("Invalid type for GREATER operation\n");
						return RUN_TIME_ERROR;
					}
				}
				push(c);
				break;
			}
			case OP_LESSER:{
				value b = pop();
				value a = pop();
				value c = (value){.type=BOOL_VAL};
				switch (a.type) {
					case INT_VAL: AS_BOOL(c) = AS_INT(a) < AS_INT(b); break;
					case FLOAT_VAL: AS_BOOL(c) = AS_FLOAT(a) < AS_FLOAT(b); break;
					default:{
						printf("Invalid type for LESSER operation\n");
						return RUN_TIME_ERROR;
					}
				}
				push(c);
				break;
			}
			case OP_GREATER_EQUAL:{
				value b = pop();
				value a = pop();
				value c = (value){.type=BOOL_VAL};
				switch (a.type) {
					case INT_VAL: AS_BOOL(c) = AS_INT(a) >= AS_INT(b); break;
					case FLOAT_VAL: AS_BOOL(c) = AS_FLOAT(a) >= AS_FLOAT(b); break;
					default:{
						printf("Invalid type for GREATER_EQUAL operation\n");
						return RUN_TIME_ERROR;
					}
				}
				push(c);
				break;
			}
			case OP_LESSER_EQUAL:{
				value b = pop();
				value a = pop();
				value c = (value){.type=BOOL_VAL};
				switch (a.type) {
					case INT_VAL: AS_BOOL(c) = AS_INT(a) <= AS_INT(b); break;
					case FLOAT_VAL: AS_BOOL(c) = AS_FLOAT(a) <= AS_FLOAT(b); break;
					default:{
						printf("Invalid type for LESSER_EQUAL operation\n");
						return RUN_TIME_ERROR;
					}
				}
				push(c);
				break;
			}
			case OP_EQUAL_EQUAL:{
				value b = pop();
				value a = pop();
				value c = (value){.type=BOOL_VAL};
				switch (a.type) {
					case INT_VAL: AS_BOOL(c) = AS_INT(a) == AS_INT(b); break;
					case FLOAT_VAL: AS_BOOL(c) = AS_FLOAT(a) == AS_FLOAT(b); break;
					case BOOL_VAL: AS_BOOL(c) = AS_BOOL(a) == AS_BOOL(b); break;
					default:{
						printf("Invalid type for EQUAL_EQUAL operation\n");
						return RUN_TIME_ERROR;
					}
				}
				push(c);
				break;
			}
			case OP_NOT_EQUAL:{
				value b = pop();
				value a = pop();
				value c = (value){.type=BOOL_VAL};
				switch (a.type) {
					case INT_VAL: AS_BOOL(c) = AS_INT(a) != AS_INT(b); break;
					case FLOAT_VAL: AS_BOOL(c) = AS_FLOAT(a) != AS_FLOAT(b); break;
					case BOOL_VAL: AS_BOOL(c) = AS_BOOL(a) != AS_BOOL(b); break;
					default:{
						printf("Invalid type for NOT_EQUAL operation\n");
						return RUN_TIME_ERROR;
					}
				}
				push(c);
				break;
			}
			case OP_AND:{
				value b = pop();
				value a = pop();
				switch (a.type) {
					case BOOL_VAL: AS_BOOL(a) = AS_BOOL(a) && AS_BOOL(b); break;
					default:{
						printf("Invalid type for AND operation\n");
						return RUN_TIME_ERROR;
					}
				}
				push(a);
				break;
			}
			case OP_OR:{
				value b = pop();
				value a = pop();
				switch (a.type) {
					case BOOL_VAL: AS_BOOL(a) = AS_BOOL(a) || AS_BOOL(b); break;
					default:{
						printf("Invalid type for OR operation\n");
						return RUN_TIME_ERROR;
					}
				}
				push(a);
				break;
			}
			default:{
				printf("Unknow instruction in VM\n");
				return RUN_TIME_ERROR;
			}
		}
	}
}
