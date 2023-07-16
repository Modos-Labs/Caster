//
// Caster waveform assembler
// 
// This tools converts human readable .csv waveform file into .bin and .mem file
// used by Caster EPDC.
// 
// Copyright 2021 Wenting Zhang
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// inih is used in this project, which is licensed under BSD-3-Clause.
// csv_parser is used in this project, which is licensed under MIT.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <libgen.h>
#include "ini.h"
#include "csv.h"

#define MAX_MODES (32) // Maximum waveform modes supported
#define MAX_TEMPS (32) // Maximum temperature ranges supported

#define MAX_CSV_LINE (1024)

#define GREYSCALE_BPP   (2)
#define GREYSCALE_LEVEL (16)

typedef struct {
    char *prefix;
    int modes;
    char **mode_names;
    int *frame_counts; // frame_counts[mode * temps + temp]
    int temps;
    int *temp_ranges;
    uint8_t ***luts; // luts[mode][temp][frame count * 256 + dst * 16 + src]
} context_t;

static int ini_parser_handler(void* user, const char* section, const char* name,
        const char* value) {
    context_t* pcontext = (context_t*)user;

    if (strcmp(section, "WAVEFORM") == 0) {
        if (strcmp(name, "VERSION") == 0) {
            assert(strcmp(value, "1.0") == 0);
        }
        else if (strcmp(name, "PREFIX") == 0) {
            pcontext->prefix = strdup(value);
        }
        else if (strcmp(name, "MODES") == 0) {
            // Allocate memory for modes
            pcontext->modes = atoi(value);
            assert(pcontext->modes <= MAX_MODES);
            pcontext->mode_names = malloc(sizeof(char*) * pcontext->modes);
            assert(pcontext->mode_names);
        }
        else if (strcmp(name, "TEMPS") == 0) {
            // Allocate memory for temp ranges
            pcontext->temps = atoi(value);
            assert(pcontext->temps <= MAX_TEMPS);
            pcontext->temp_ranges = malloc(sizeof(int) * pcontext->temps);
            assert(pcontext->temp_ranges);
            pcontext->frame_counts = malloc(sizeof(int) * pcontext->modes *
                    pcontext->temps);
            assert(pcontext->frame_counts);
        }
        else {
            size_t len = strlen(name);
            if ((len >= 7) && (name[0] == 'T') &&
                    (strncmp(name + (len - 5), "RANGE", 5) == 0)) {
                // Temperature Range
                char *temp_id_s = strdup(name);
                temp_id_s[len - 5] = '\0';
                int temp_id = atoi(temp_id_s + 1);
                free(temp_id_s);
                pcontext->temp_ranges[temp_id] = atoi(value);
            }
            else {
                fprintf(stderr, "Unknown name %s=%s\n", name, value);
                return 0; // Unknown name
            }
        }
    }
    else if (strncmp(section, "MODE", 4) == 0) {
        int mode_id = atoi(section + 4);
        assert(mode_id >= 0);
        assert(mode_id < pcontext->modes);
        size_t len = strlen(name);
        if (strcmp(name, "NAME") == 0) {
            // Mode Name
            pcontext->mode_names[mode_id] = strdup(value);
        }
        else if ((len >= 4) && (name[0] == 'T') &&
                (strncmp(name + (len - 2), "FC", 2) == 0)) {
            // Frame Count
            char *temp_id_s = strdup(name);
            temp_id_s[len - 2] = '\0';
            int temp_id = atoi(temp_id_s + 1);
            free(temp_id_s);
            pcontext->frame_counts[pcontext->temps * mode_id + temp_id]
                    = atoi(value);
        }
    }
    else {
        fprintf(stderr, "Unknown section %s\n", section);
        return 0; // Unknown section
    }
    return 1;
}

static void write_uint64_le(uint8_t* dst, uint64_t val) {
    dst[7] = (val >> 56) & 0xff;
    dst[6] = (val >> 48) & 0xff;
    dst[5] = (val >> 40) & 0xff;
    dst[4] = (val >> 32) & 0xff;
    dst[3] = (val >> 24) & 0xff;
    dst[2] = (val >> 16) & 0xff;
    dst[1] = (val >> 8) & 0xff;
    dst[0] = (val) & 0xff;
}

static void parse_range(const char* str, int* begin, int* end) {
    // Parse range specified in the waveform.
    // Example:
    // 2 - 2 to 2
    // 0:15 - 0 to 15
    // 4:7 - 4 to 7
    char* delim = strchr(str, ':');
    if (delim) {
        *begin = atoi(str);
        *end = atoi(delim + 1);
    }
    else {
        *begin = atoi(str);
        *end = *begin;
    }
}

static void load_waveform_csv(const char* filename, int frame_count,
        uint8_t* lut) {
    FILE* fp = fopen(filename, "r");
    assert(fp);

    // Unspecified parts of LUT will be filled with 3 instead of 0 for debugging
    memset(lut, 3, frame_count * 256);

    char* line;
    int done = 0;
    int err = 0;
    int rst = 1; // Reset fread_csv_line internal state in the first call
    while (!done) {
        line = fread_csv_line(fp, MAX_CSV_LINE, &done, &err, rst);
        rst = 0;
        if (!line) continue;
        char** parsed = parse_csv(line);
        if (!parsed) continue;
        // Parse source/ destination range
        int src0, src1, dst0, dst1;
        // Skip empty lines
        if (!parsed[0]) continue;
        if (!parsed[1]) continue;
        parse_range(parsed[0], &src0, &src1);
        parse_range(parsed[1], &dst0, &dst1);
        // Fill in LUT
        for (int i = 0; i < frame_count; i++) {
            assert(parsed[i]);
            uint8_t val = atoi(parsed[i + 2]);
            for (int src = src0; src <= src1; src++) {
                for (int dst = dst0; dst <= dst1; dst++) {
                    lut[i * 256 + dst * 16 + src] = val;
                }
            }
        }
        free_csv_line(parsed);
        free(line);
    }

    fclose(fp);
}

static void dump_lut(int frame_count, uint8_t* lut) {
    for (int src = 0; src < 16; src++) {
        for (int dst = 0; dst < 16; dst++) {
            printf("%x -> %x: ", src, dst);
            for (int frame = 0; frame < frame_count; frame++) {
                printf("%d ", lut[frame * 256 + dst * 16 + src]);
            }
            printf("\n");
        }
    }
}

static void copy_lut(uint8_t* dst, uint8_t* src, size_t src_count) {
    for (size_t i = 0; i < src_count / 4; i++) {
        uint8_t val;
        val = *src++;
        val <<= 2;
        val |= *src++;
        val <<= 2;
        val |= *src++;
        val <<= 2;
        val |= *src++;
        *dst++ = val;
    }
}

int main(int argc, char *argv[]) {
    context_t context;
    
    printf("Caster waveform assembler\n");

    // Load waveform descriptor
    if (argc < 3) {
        fprintf(stderr, "Usage: caster_wvfm_asm input_file output_path\n");
        fprintf(stderr, "Example: caster_wvfm_asm e060scm_desc.iwf output\n");
        return 1;
    }

    char* input_fn = argv[1];
    char* output_path = argv[2];

    if (ini_parse(input_fn, ini_parser_handler, &context) < 0) {
        fprintf(stderr, "Failed to load waveform descriptor.\n");
        return 1;
    }

    // Set default name if not provided
    char* default_name = "Unknown";
    for (int i = 0; i < context.modes; i++) {
        if (!context.mode_names[i])
            context.mode_names[i] = strdup(default_name);
    }

    // Print loaded info
    printf("Prefix: %s\n", context.prefix);

    for (int i = 0; i < context.modes; i++) {
        printf("Mode %d: %s\n", i, context.mode_names[i]);
        for (int j = 0; j < context.temps; j++) {
            printf("\tTemp %d: %d frames\n", j,
                    context.frame_counts[i * context.temps + j]);
        }
    }

    for (int i = 0; i < context.temps; i++) {
        printf("Temp %d: %d degC\n", i, context.temp_ranges[i]);
    }

    assert(context.modes < 100);
    assert(context.temps < 100);

    // Load actual waveform
    char *dir = dirname(input_fn); // Return val of dirname shall not be free()d
    size_t dirlen = strlen(dir);
    context.luts = malloc(context.modes * sizeof(uint8_t**));
    char* fn = malloc(dirlen + strlen(context.prefix) + 14);
    assert(fn);
    assert(context.luts);
    for (int i = 0; i < context.modes; i++) {
        context.luts[i] = malloc(context.temps * sizeof(uint8_t*));
        assert(context.luts[i]);
        for (int j = 0; j < context.temps; j++) {
            int frame_count = context.frame_counts[i * context.temps + j];
            context.luts[i][j] = malloc(frame_count * 256); // LUT always in 8b
            assert(context.luts[i][j]);
            sprintf(fn, "%s/%s_M%d_T%d.csv", dir, context.prefix, i, j);
            printf("Loading %s...\n", fn);
            load_waveform_csv(fn, frame_count, context.luts[i][j]);
            
        }
    }
    free(fn);


    // Fill waveform data
    uint8_t* wvfm = malloc(4*1024); // each table is always 4KB
    fn = malloc(strlen(output_path) + strlen(context.prefix) + 14);
    for (int i = 0; i < context.modes; i++) {
        for (int j = 0; j < context.temps; j++) {
            size_t index = i * context.temps + j;
            int frame_count = context.frame_counts[index];
            if (frame_count > 64)
                continue;
            memset(wvfm, 0, 4*1024);
            copy_lut(wvfm, context.luts[i][j], frame_count * 256);
            // Write out binary version
            sprintf(fn, "%s/%s_M%d_T%d.bin", output_path, context.prefix, i, j);
            FILE *outFile = fopen(fn, "wb");
            assert(outFile);
            size_t written = fwrite(wvfm, 4*1024, 1, outFile);
            assert(written == 1);
            fclose(outFile);
            // Write out text version
            sprintf(fn, "%s/%s_M%d_T%d.mem", output_path, context.prefix, i, j);
            outFile = fopen(fn, "w");
            assert(outFile);
            uint8_t *prd = wvfm;
            for (int f = 0; f < 4 * 1024; f++) {
                fprintf(outFile, "%02x\n", *prd++);
            }
            fclose(outFile);
        }
    }
    free(fn);

    printf("Finished.\n");

    // Free buffers
    free(context.prefix);
    for (int i = 0; i < context.modes; i++) {
        free(context.mode_names[i]);
        for (int j = 0; j < context.temps; j++) {
            free(context.luts[i][j]);
        }
        free(context.luts[i]);
    }
    free(context.mode_names);
    free(context.luts);
    free(context.frame_counts);
    free(context.temp_ranges);

    return 0;
}
