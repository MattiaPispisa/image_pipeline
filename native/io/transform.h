#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

bool init_engine(const char* argv0);
void shutdown_engine();

uint8_t* transform_image(const uint8_t* input_buffer, size_t input_length, const int32_t* ops_array, size_t ops_count, size_t* out_length);

void free_image_buffer(uint8_t* buffer);