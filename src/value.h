#ifndef value_h
#define value_h

#include <stdint.h>
#include <stdbool.h>

typedef enum{
	INT_VAL, FLOAT_VAL, BOOL_VAL
} value_type;

typedef struct{
	value_type type;
	union{
		bool boolean;
		int32_t int_number;
		float float_number;
	} as;
} value;

typedef struct{
	uint32_t len;
	uint32_t capacity;
	value* value;
} value_array;

value_array init_value_array();
void resize_value_array(value_array* val_array, uint32_t new_capacity);
void write_value_array(value_array* value_array, value val);
void deinit_value_array(value_array* value_array);
void print_value(value value);
void print_value_array(value_array* value_array, char* label);

#endif
