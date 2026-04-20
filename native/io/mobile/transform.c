#include "../transform.h"

#include <math.h>

// Definendo queste macro PRIMA degli include, diciamo al compilatore
// di inserire l'implementazione del codice proprio qui dentro.
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "stb_image_resize2.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// STB non ha bisogno di essere inizializzato o spento.
// Rispettiamo l'interfaccia FFI tornando semplicemente true.
bool init_engine(const char* argv0) { return true; }
void shutdown_engine() {}

// --- STRUTTURA E CALLBACK PER SCRIVERE IN MEMORIA ---
typedef struct {
    uint8_t* buffer;
    size_t size;
    size_t capacity;
} MemoryContext;

void write_to_mem(void *context, void *data, int size) {
    MemoryContext *mem = (MemoryContext *)context;
    
    // Se non c'è abbastanza spazio, raddoppiamo la capacità
    if (mem->size + size > mem->capacity) {
        mem->capacity = (mem->size + size) * 2;
        mem->buffer = (uint8_t*)realloc(mem->buffer, mem->capacity);
    }
    
    // Copiamo i nuovi byte nel nostro buffer
    memcpy(mem->buffer + mem->size, data, size);
    mem->size += size;
}
// ----------------------------------------------------

uint8_t* transform_image(const uint8_t* input_buffer, size_t input_length, const int32_t* ops_array, size_t ops_count, size_t* out_length) {
    
    int width, height, channels;
    
    // 1. CARICAMENTO (Decodifica il buffer in array di pixel non compressi)
    // Richiediamo 0 canali di default (manterrà RGB o RGBA originali)
    uint8_t *img_data = stbi_load_from_memory(input_buffer, (int)input_length, &width, &height, &channels, 0);
    if (!img_data) return NULL;

    int export_quality = 75; // Default

    // --- INTERPRETAZIONE DELL'ARRAY NUMERICO ---
    size_t i = 0;
    while (i < ops_count) {
        int32_t op_type = ops_array[i++];

        // 1 = RESIZE (si aspetta max_w e max_h)
        if (op_type == 1 && i + 1 < ops_count) {
            int32_t max_w = ops_array[i++];
            int32_t max_h = ops_array[i++];

            double scale_x = 1.0, scale_y = 1.0;
            if (max_w > 0) scale_x = (double)max_w / width;
            if (max_h > 0) scale_y = (double)max_h / height;

            // Logica "Fit Box"
            double scale = 1.0;
            if (max_w > 0 && max_h > 0) {
                scale = (scale_x < scale_y) ? scale_x : scale_y;
            } else if (max_w > 0) {
                scale = scale_x;
            } else if (max_h > 0) {
                scale = scale_y;
            }

            // Non permettiamo di ingrandire l'immagine (upscaling non permesso)
            if (scale > 1.0) {
                scale = 1.0;
            }

            if (scale != 1.0) {
                int new_w = (int)(width * scale);
                int new_h = (int)(height * scale);
                
                // Evitiamo dimensioni invalide (0x0)
                if (new_w < 1) new_w = 1;
                if (new_h < 1) new_h = 1;

                // Alloco la memoria per l'immagine ridimensionata
                uint8_t *resized_data = (uint8_t*)malloc(new_w * new_h * channels);
                
                // Eseguo il resize lineare. (stbir_pixel_layout mappa direttamente al numero di canali 1-4)
                stbir_resize_uint8_linear(
                    img_data, width, height, 0, 
                    resized_data, new_w, new_h, 0, 
                    (stbir_pixel_layout)channels
                );
                
                // Libero la vecchia immagine e aggiorno i puntatori
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

    // --- ESPORTAZIONE ---
    // Inizializziamo il nostro contesto di memoria dinamica
    MemoryContext mem;
    mem.capacity = 1024 * 1024; // Partiamo con 1MB preallocato per efficienza
    mem.size = 0;
    mem.buffer = (uint8_t*)malloc(mem.capacity);

    // Scriviamo il JPG in memoria tramite la nostra callback
    int write_success = stbi_write_jpg_to_func(write_to_mem, &mem, width, height, channels, img_data, export_quality);

    // L'immagine decompressa non ci serve più
    stbi_image_free(img_data); 

    if (!write_success) {
        free(mem.buffer);
        return NULL;
    }

    *out_length = mem.size;
    return mem.buffer;
}

// Funzione chiamata da Dart per liberare il buffer finale
void free_image_buffer(uint8_t* buffer) {
    if (buffer) {
        free(buffer); 
    }
}