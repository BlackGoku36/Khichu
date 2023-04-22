#include "parser.h"
#include <stdio.h>
#include <stdlib.h>
#include "chunk.h"

int main(void){

	// FILE* file_ptr;
	// file_ptr = fopen("test.ul", "r");

	// if(file_ptr == NULL) return 1;

	// fseek(file_ptr, 0L, SEEK_END);
	// long numbytes = ftell(file_ptr);

	// fseek(file_ptr, 0L, SEEK_SET);

	// char* buffer = (char*) calloc(numbytes, sizeof(char));

	// if(buffer == NULL) return 1;

	// fread(buffer, sizeof(char), numbytes, file_ptr);
	// fclose(file_ptr);

	// token_pool tokens = scanner(buffer, numbytes);
	// for (uint32_t i = 0; i < tokens.cursor; i++) {
	// 	print_token(buffer, tokens.pool[i]);
	// }

	// parse(&tokens, buffer);

	// free(buffer);

	chunk chunk = init_chunk();
	write_chunk(&chunk, OP_RETURN);
	print_chunk(&chunk, "Test");
	deinit_chunk(&chunk);

	return 0;
}
