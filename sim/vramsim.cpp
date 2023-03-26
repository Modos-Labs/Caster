//
// Caster simulator
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
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "vramsim.h"

// 160*120*2 = 38.4KB = 4.8Kw
#define VRAM_SIZE 8192
static uint64_t vram[VRAM_SIZE];
static size_t rdptr, wrptr;
static uint8_t last_trigger;

//#define TRIGGER 2070

void vramsim_reset() {
    memset(vram, 0, VRAM_SIZE * sizeof(uint64_t));
    rdptr = 0;
    wrptr = 0;
    last_trigger = 0;
}

static void print_pixel(uint16_t pixel) {
    int mode = ((pixel >> 14) & 0x3);
    int fcnt = ((pixel >> 4) & 0x3f);
    int pixl = ((pixel) & 0xf);
    printf("Mode: %d, Fcnt: %d, Pixl: %d\n", mode, fcnt, pixl);
}

void vramsim_apply(uint8_t b_trigger, uint64_t &bi_pixel, uint8_t &bi_valid,
        uint8_t bi_ready, uint64_t bo_pixel, uint8_t bo_valid) {
    if (!last_trigger && b_trigger) {
        rdptr = 0;
        wrptr = 0;
    }
    bi_valid = 1;
    if (bi_ready) {
        bi_pixel = vram[rdptr++];
#ifdef TRIGGER
        if (rdptr == TRIGGER) {
            printf("Rd\n");
            print_pixel(bi_pixel & 0xffff);
            print_pixel((bi_pixel >> 16) & 0xffff);
            print_pixel((bi_pixel >> 32) & 0xffff);
            print_pixel((bi_pixel >> 48) & 0xffff);
        }
#endif
    }
    if (bo_valid) {
        vram[wrptr++] = bo_pixel;
#ifdef TRIGGER
        if (wrptr == TRIGGER) {
            printf("Wr\n");
            print_pixel(bo_pixel & 0xffff);
            print_pixel((bo_pixel >> 16) & 0xffff);
            print_pixel((bo_pixel >> 32) & 0xffff);
            print_pixel((bo_pixel >> 48) & 0xffff);
        }
#endif
    }
    last_trigger = b_trigger;
}
