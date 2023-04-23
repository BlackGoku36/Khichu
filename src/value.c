#include "value.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#define VALUE_ARRAY_INIT_CAPACITY 20

value_array init_value_array(){
	value* values = (value*) malloc(sizeof(value) * VALUE_ARRAY_INIT_CAPACITY);
	assert(values != NULL);
	return (value_array){
		.len = 0,
		.capacity = VALUE_ARRAY_INIT_CAPACITY,
		.value = values,
	};
}

void resize_value_array(value_array* val_array, uint32_t new_capacity){
	assert(new_capacity > 0);
	value* new_value_array = (value*) realloc(val_array->value, new_capacity);
	assert(new_value_array != NULL);
	val_array->value = new_value_array;
}

void write_value_array(value_array* value_array, value val){
	if(value_array->len + 1 > value_array->capacity){
		resize_value_array(value_array, value_array->capacity * 2);
	}
	value_array->value[value_array->len] = val;
	value_array->len += 1;
}

void deinit_value_array(value_array* value_array){
	free(value_array->value);
	value_array->len = 0;
	value_array->capacity = 0;
	value_array->value = NULL;
}

void print_value(value value){
	switch (value.type) {
		case INT_VAL: printf("%d (INT)\n", value.as.int_number); break;
		case FLOAT_VAL: printf("%f (FLOAT)\n", value.as.float_number); break;
		case BOOL_VAL: printf("%d (BOOL)\n", value.as.boolean); break;
	}
}

void print_value_array(value_array* value_array, char* label){
	printf("--- value array: %s ---\n", label);
	for (uint32_t i = 0; i < value_array->len; i++) {
		printf("%d: ", i);
		print_value(value_array->value[i]);
	}
}
