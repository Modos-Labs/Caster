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
#define MAX_TABLES (MAX_MODES * MAX_TEMPS)

#define MAX_FRAMES  (64) // default 64

#define MAX_CSV_LINE (1024)

#define GREYSCALE_BPP   (2)
#define GREYSCALE_LEVEL (16)

typedef struct {
    char *prefix;
    int modes;
    char **mode_names;
    int temps;
    int *temp_ranges;
    int tables;
    int *table_ids; // table_ids[mode][temp]
    int *frame_counts; // frame_counts[tables]
    int inbpp;
    int unidir;
    int outbpp;
    uint8_t **luts; // luts[table][frame count * 256 + dst * 16 + src]
} context_t;

static int ini_parser_handler(void* user, const char* section, const char* name,
        const char* value) {
    context_t* pcontext = (context_t*)user;

    if (strcmp(section, "WAVEFORM") == 0) {
        if (strcmp(name, "VERSION") == 0) {
            assert((strcmp(value, "2.0") == 0) || (strcmp(value, "2.1") == 0));
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
        }
        else if (strcmp(name, "TABLES") == 0) {
            // Allocate memory for tables
            pcontext->tables = atoi(value);
            assert(pcontext->tables <= MAX_TABLES);
            pcontext->table_ids = malloc(sizeof(int) * pcontext->modes *
                    pcontext->temps);
            assert(pcontext->table_ids);
            pcontext->frame_counts = malloc(sizeof(int) * pcontext->tables);
            assert(pcontext->frame_counts);
        }
        else if (strcmp(name, "BPP") == 0) {
            pcontext->inbpp = atoi(value);
        }
        else if (strcmp(name, "OUTBPP") == 0) {
            pcontext->outbpp = atoi(value);
        }
        else if (strcmp(name, "UNIDIR") == 0) {
            pcontext->unidir = atoi(value);
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
            else if ((len >= 5) && (strncmp(name, "TB", 2) == 0) &&
                    (strncmp(name + (len - 2), "FC", 2) == 0)) {
                // Frame count
                char *table_id_s = strdup(name);
                table_id_s[len - 2] = '\0';
                int table_id = atoi(table_id_s + 2);
                free(table_id_s);
                pcontext->frame_counts[table_id] = atoi(value);
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
        else if ((len >= 7) && (name[0] == 'T') &&
                (strncmp(name + (len - 5), "TABLE", 2) == 0)) {
            // Frame Count
            char *table_id_s = strdup(name);
            table_id_s[len - 2] = '\0';
            int table_id = atoi(table_id_s + 1);
            free(table_id_s);
            pcontext->table_ids[table_id] = atoi(value);
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
        uint8_t* lut, int inbpp, int unidir) {
    FILE* fp = fopen(filename, "r");
    assert(fp);

    memset(lut, 0, frame_count * 256);

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
        parse_range(parsed[0], &src0, &src1);
        // Fill in LUT
        if (unidir) {
            // 1D LUT
            for (int i = 0; i < frame_count; i++) {
                assert(parsed[i]);
                uint8_t val = atoi(parsed[i + 1]);
                for (int src = src0; src <= src1; src++) {
                    lut[i * 16 + src] = val;
                }
            }
        }
        else {
            // 2D LUT
            if (!parsed[1]) continue;
            parse_range(parsed[1], &dst0, &dst1);
            for (int i = 0; i < frame_count; i++) {
                assert(parsed[i]);
                uint8_t val = atoi(parsed[i + 2]);
                for (int src = src0; src <= src1; src++) {
                    for (int dst = dst0; dst <= dst1; dst++) {
                        lut[i * 256 + dst * 16 + src] = val;
                    }
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

static void copy_lut_4bpp(uint8_t* dst, uint8_t* src, size_t src_count) {
    for (size_t i = 0; i < src_count / 2; i++) {
        uint8_t val;
        val = *src++;
        val <<= 4;
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

    memset(&context, 0, sizeof(context));
    // Set default values for backwards compatibility
    context.unidir = 0;
    context.inbpp = 4;
    context.outbpp = 2;

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

    assert(context.modes < MAX_MODES);
    assert(context.temps < MAX_TEMPS);

    if (context.inbpp != 4) {
        printf("5bpp waveform not supported. Use 5bpp to 4bpp tool to convert it first\n");
        exit(1);
    }

    // Load actual waveform
    uint32_t frame_size = context.unidir ? 16 : 256;
    char *dir = dirname(input_fn); // Return val of dirname shall not be free()d
    size_t dirlen = strlen(dir);
    context.luts = malloc(context.tables * sizeof(uint8_t*));
    char* fn = malloc(dirlen + strlen(context.prefix) + 14);
    assert(fn);
    assert(context.luts);
    for (int i = 0; i < context.tables; i++) {
        int frame_count = context.frame_counts[i];
        context.luts[i] = malloc(frame_count * frame_size); // LUT always in 8b
        assert(context.luts[i]);
        sprintf(fn, "%s/%s_TB%d.csv", dir, context.prefix, i);
        printf("Loading %s...\n", fn);
        load_waveform_csv(fn, frame_count, context.luts[i], context.inbpp,
                context.unidir);
    }
    free(fn);


    // Fill waveform data
    size_t binsize = MAX_FRAMES * 16 * 16 * context.outbpp / 8;
    uint8_t* wvfm = malloc(binsize);
    fn = malloc(strlen(output_path) + strlen(context.prefix) + 14);
    int max_frames = MAX_FRAMES * (context.unidir ? 16 : 1); 
    for (int i = 0; i < context.tables; i++) {
        int frame_count = context.frame_counts[i];
        if (frame_count > max_frames) {
            printf("Table %d too long to fit, skipping...\n", i);
            continue;
        }
        memset(wvfm, 0, binsize);
        if (context.outbpp == 2)
            copy_lut(wvfm, context.luts[i], frame_count * frame_size);
        else
            copy_lut_4bpp(wvfm, context.luts[i], frame_count * frame_size);
        // Write out binary version
        sprintf(fn, "%s/%s_TB%d.bin", output_path, context.prefix, i);
        FILE *outFile = fopen(fn, "wb");
        assert(outFile);
        size_t written = fwrite(wvfm, binsize, 1, outFile);
        assert(written == 1);
        fclose(outFile);
        // Write out text version
        sprintf(fn, "%s/%s_TB%d.mem", output_path, context.prefix, i);
        outFile = fopen(fn, "w");
        assert(outFile);
        uint8_t *prd = wvfm;
        for (int f = 0; f < binsize; f++) {
            fprintf(outFile, "%02x\n", *prd++);
        }
        fclose(outFile);
        sprintf(fn, "%s/%s_TB%d.h", output_path, context.prefix, i);
        outFile = fopen(fn, "w");
        assert(outFile);
        fprintf(outFile, "const unsigned char %s_TB%d[%zu] = {\n", context.prefix, i, binsize);
        prd = wvfm;
        for (int i = 0; i < binsize / 8; i++) {
            fprintf(outFile, "   ");
            for (int j = 0; j < 8; j++) {
                fprintf(outFile, " 0x%02x,", *prd++);
            }
            fprintf(outFile, "\n");
        }
        fprintf(outFile, "};");
        fclose(outFile);
    }
    free(fn);

    printf("Finished.\n");

    // Free buffers
    free(context.prefix);
    for (int i = 0; i < context.modes; i++) {
        free(context.mode_names[i]);
    }
    for (int i = 0; i < context.tables; i++) {
        free(context.luts[i]);
    }
    free(context.mode_names);
    free(context.luts);
    free(context.frame_counts);
    free(context.temp_ranges);

    return 0;
}
