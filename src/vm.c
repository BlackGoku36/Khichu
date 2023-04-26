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
					default:
						printf("Invalid type for NEGATE operation\n");
				}
				push(val);
				break;
			}
			case OP_ADD:{
				value b = pop();
				value a = pop();
				// TODO: Need to check type of both values?
				switch (a.type) {
					case INT_VAL: AS_INT(a) += AS_INT(b); break;
					case FLOAT_VAL: AS_FLOAT(a) += AS_FLOAT(b); break;
					default:
						printf("Invalid type(s) for ADD operation\n");
				}
				push(a);
				break;
			}
			case OP_SUB:{
				value b = pop();
				value a = pop();
				// TODO: Need to check type of both values?
				switch (a.type) {
					case INT_VAL: AS_INT(a) -= AS_INT(b); break;
					case FLOAT_VAL: AS_FLOAT(a) -= AS_FLOAT(b); break;
					default:
						printf("Invalid type(s) for SUB operation\n");
				}
				push(a);
				break;
			}
			case OP_MULT:{
				value b = pop();
				value a = pop();
				// TODO: Need to check type of both values?
				switch (a.type) {
					case INT_VAL: AS_INT(a) *= AS_INT(b); break;
					case FLOAT_VAL: AS_FLOAT(a) *= AS_FLOAT(b); break;
					default:
						printf("Invalid type(s) for MULT operation\n");
				}
				push(a);
				break;
			}
			case OP_DIV:{
				value b = pop();
				value a = pop();
				// TODO: Need to check type of both values?
				switch (a.type) {
					case INT_VAL: AS_INT(a) /= AS_INT(b); break;
					case FLOAT_VAL: AS_FLOAT(a) /= AS_FLOAT(b); break;
					default:
						printf("Invalid type(s) for DIV operation\n");
				}
				push(a);
				break;
			}
		}
	}
}
