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

#define INT_VALUE(val)   ((value){.type=INT_VAL, .as.int_number=val})
#define FLOAT_VALUE(val) ((value){.type=FLOAT_VAL, .as.float_number=val})
#define BOOL_VALUE(val)  ((value){.type=BOOL_VAL, .as.boolean=val})
#define EMPTY_VALUE  ((value){})

#define AS_INT(val)   ((val).as.int_number)
#define AS_FLOAT(val) ((val).as.float_number)
#define AS_BOOL(val)  ((val).as.boolean)

#define GET_TYPE(val) ((val).type)
#define IS_INT(val) ((val).type == INT_VAL)
#define IS_FLOAT(val) ((val).type == FLOAT_VAL)
#define IS_BOOL(val) ((val).type == BOOL_VAL)

value_array init_value_array();
void resize_value_array(value_array* val_array, uint32_t new_capacity);
void write_value_array(value_array* value_array, value val);
void deinit_value_array(value_array* value_array);
void print_value(value value);
void print_value_array(value_array* value_array, char* label);

#endif
