#include "parser.h"
#include <stdio.h>
#include <stdlib.h>
#include "chunk.h"
#include "vm.h"

int main(void){

	FILE* file_ptr;
	file_ptr = fopen("test.ul", "r");

	if(file_ptr == NULL) return 1;

	fseek(file_ptr, 0L, SEEK_END);
	long numbytes = ftell(file_ptr);

	fseek(file_ptr, 0L, SEEK_SET);

	char* buffer = (char*) calloc(numbytes, sizeof(char));

	if(buffer == NULL) return 1;

	fread(buffer, sizeof(char), numbytes, file_ptr);
	fclose(file_ptr);

	token_pool tokens = scanner(buffer, numbytes);
	printf("\n----- TOKENS -----\n");
	for (uint32_t i = 0; i < tokens.cursor; i++) {
		print_token(buffer, tokens.pool[i]);
	}

	init_vm();
	chunk chunk = init_chunk();
	parse(&tokens, buffer, &chunk);
	free(buffer);
	print_chunk(&chunk, "Test");
	printf("\n----- VM -----\n");
	interpret(&chunk);
	free_vm();
	deinit_chunk(&chunk);

	return 0;
}
