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
			case OP_NEGATE:{
				value val = pop();
				switch (val.type) {
					case INT_VAL: val.as.int_number = -val.as.int_number; break;
					case FLOAT_VAL: val.as.float_number = -val.as.float_number; break;
					default:
						printf("Invalid type for negate operation\n");
				}
				push(val);
				break;
			}
			case OP_ADD:{
				value b = pop();
				value a = pop();
				// TODO: Need to check type of both values?
				switch (a.type) {
					case INT_VAL: a.as.int_number += b.as.int_number; break;
					case FLOAT_VAL: a.as.float_number += b.as.float_number; break;
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
					case INT_VAL: a.as.int_number -= b.as.int_number; break;
					case FLOAT_VAL: a.as.float_number -= b.as.float_number; break;
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
					case INT_VAL: a.as.int_number *= b.as.int_number; break;
					case FLOAT_VAL: a.as.float_number *= b.as.float_number; break;
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
					case INT_VAL: a.as.int_number /= b.as.int_number; break;
					case FLOAT_VAL: a.as.float_number /= b.as.float_number; break;
					default:
						printf("Invalid type(s) for DIV operation\n");
				}
				push(a);
				break;
			}
		}
	}
}