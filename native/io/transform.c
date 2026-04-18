#include "transform.h"
#include <vips/vips.h>
#include <stdio.h>

bool init_vips(const char* argv0) { return VIPS_INIT(argv0) == 0; }
void shutdown_vips() { vips_shutdown(); }

uint8_t* transform_image(const uint8_t* input_buffer, size_t input_length, const int32_t* ops_array, size_t ops_count, size_t* out_length) {
    VipsImage *image = vips_image_new_from_buffer(input_buffer, input_length, "", NULL);
    if (!image) return NULL;

    int export_quality = 75; // Default

    // --- INTERPRETAZIONE DELL'ARRAY NUMERICO ---
    size_t i = 0;
    while (i < ops_count) {
        int32_t op_type = ops_array[i++];

        // 1 = RESIZE (si aspetta max_w e max_h)
        if (op_type == 1 && i + 1 < ops_count) {
            int32_t max_w = ops_array[i++];
            int32_t max_h = ops_array[i++];

            int in_width = vips_image_get_width(image);
            int in_height = vips_image_get_height(image);

            double scale_x = 1.0, scale_y = 1.0;
            
            if (max_w > 0) scale_x = (double)max_w / in_width;
            if (max_h > 0) scale_y = (double)max_h / in_height;

            // Logica "Fit Box" (prendiamo la scala minore tra le due, ignorando lo 0)
            double scale = 1.0;
            if (max_w > 0 && max_h > 0) {
                scale = (scale_x < scale_y) ? scale_x : scale_y;
            } else if (max_w > 0) {
                scale = scale_x;
            } else if (max_h > 0) {
                scale = scale_y;
            }

            if (scale != 1.0) {
                VipsImage *resized = NULL;
                if (vips_resize(image, &resized, scale, NULL) == 0) {
                    g_object_unref(image);
                    image = resized;
                } else {
                    vips_error_clear();
                }
            }
        } 
        // 2 = SET QUALITY (si aspetta un parametro)
        else if (op_type == 2 && i < ops_count) {
            export_quality = ops_array[i++];
            if (export_quality < 0) export_quality = 0;
            if (export_quality > 100) export_quality = 100;
        } 
        // Formato array non valido, interrompi lettura
        else {
            break; 
        }
    }

    // --- ESPORTAZIONE ---
    char format_string[32];
    snprintf(format_string, sizeof(format_string), ".jpg[Q=%d]", export_quality);

    void *out_buf = NULL;
    size_t out_len = 0;

    if (vips_image_write_to_buffer(image, format_string, &out_buf, &out_len, NULL) != 0) {
        vips_error_clear();
        g_object_unref(image);
        return NULL;
    }

    *out_length = out_len;
    g_object_unref(image);
    return (uint8_t*)out_buf;
}

void free_image_buffer(uint8_t* buffer) {
    if (buffer) {
        g_free(buffer);
    }
}