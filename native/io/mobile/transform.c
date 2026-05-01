#include "../transform.h"

#include <math.h>

// Define macros before includes to inject the implementation.
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "stb_image_resize2.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// STB doesn't require initialization. Returning true for FFI compatibility.
bool init_engine(const char* argv0) { return true; }
void shutdown_engine() {}

// Memory context and callback for buffer writing
typedef struct {
    uint8_t* buffer;
    size_t size;
    size_t capacity;
} MemoryContext;

void write_to_mem(void *context, void *data, int size) {
    MemoryContext *mem = (MemoryContext *)context;
    
    // Double capacity if current space is insufficient.
    if (mem->size + size > mem->capacity) {
        mem->capacity = (mem->size + size) * 2;
        mem->buffer = (uint8_t*)realloc(mem->buffer, mem->capacity);
    }
    
    memcpy(mem->buffer + mem->size, data, size);
    mem->size += size;
}
// ----------------------------------------------------

uint8_t* transform_image(const uint8_t* input_buffer, size_t input_length, const int32_t* ops_array, size_t ops_count, size_t* out_length) {
    
    int width, height, channels;
    
    // Decode input buffer into raw pixels.
    // Defaulting to 0 channels to preserve original format (RGB/RGBA).
    uint8_t *img_data = stbi_load_from_memory(input_buffer, (int)input_length, &width, &height, &channels, 0);
    if (!img_data) return NULL;

    int export_quality = 75; // Default

    size_t i = 0;
    while (i < ops_count) {
        int32_t op_type = ops_array[i++];

        // Resize operation (expects max_w and max_h)
        if (op_type == 1 && i + 1 < ops_count) {
            int32_t max_w = ops_array[i++];
            int32_t max_h = ops_array[i++];

            double scale_x = 1.0, scale_y = 1.0;
            if (max_w > 0) scale_x = (double)max_w / width;
            if (max_h > 0) scale_y = (double)max_h / height;

            // Fit box logic
            double scale = 1.0;
            if (max_w > 0 && max_h > 0) {
                scale = (scale_x < scale_y) ? scale_x : scale_y;
            } else if (max_w > 0) {
                scale = scale_x;
            } else if (max_h > 0) {
                scale = scale_y;
            }

            // Upscaling is not allowed.
            if (scale > 1.0) {
                scale = 1.0;
            }

            if (scale != 1.0) {
                int new_w = (int)(width * scale);
                int new_h = (int)(height * scale);
                
                if (new_w < 1) new_w = 1;
                if (new_h < 1) new_h = 1;

                // Allocate memory for the resized image
                uint8_t *resized_data = (uint8_t*)malloc(new_w * new_h * channels);
                
                // Execute linear resize. (stbir_pixel_layout maps directly to channel count 1-4)
                stbir_resize_uint8_linear(
                    img_data, width, height, 0, 
                    resized_data, new_w, new_h, 0, 
                    (stbir_pixel_layout)channels
                );
                
                stbi_image_free(img_data);
                img_data = resized_data;
                width = new_w;
                height = new_h;
            }
        } 
        // 2 = SET QUALITY
        else if (op_type == 2 && i < ops_count) {
            export_quality = ops_array[i++];
            if (export_quality < 0) export_quality = 0;
            if (export_quality > 100) export_quality = 100;
        } else {
            break; 
        }
    }

    // Initialize dynamic memory context (1MB pre-allocated for efficiency).
    MemoryContext mem;
    mem.capacity = 1024 * 1024;
    mem.size = 0;
    mem.buffer = (uint8_t*)malloc(mem.capacity);

    // Encode to JPG via callback.
    int write_success = stbi_write_jpg_to_func(write_to_mem, &mem, width, height, channels, img_data, export_quality);

    stbi_image_free(img_data); 

    if (!write_success) {
        free(mem.buffer);
        return NULL;
    }

    *out_length = mem.size;
    return mem.buffer;
}

// Free the buffer allocated in transform_image.
void free_image_buffer(uint8_t* buffer) {
    if (buffer) {
        free(buffer); 
    }
}