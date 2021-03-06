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
#include <string.h>
#include "dispsim.h"

static uint8_t localbuf[DISP_WIDTH * DISP_HEIGHT];

static int x_counter;
static int y_counter;
static int last_hs;

#define SPEED 28

void render_copy(); // Function in main.cpp

void dispsim_set_pixel(uint32_t *pixels, int x, int y, uint8_t input) {
    uint32_t pixel = localbuf[y * DISP_WIDTH + x];
    if (input == 1) {
        // black
        if (pixel > SPEED)
            pixel -= SPEED;
        else
            pixel = 0;
    }
    else if (input == 2) {
        // white
        if (pixel < 255 - SPEED)
            pixel += SPEED;
        else {
            //printf("Location %d %d, overdriving, not good\n", x, y);
            pixel = 255;
        }
    }
    // otherwise, nop
    localbuf[y * DISP_WIDTH + x] = pixel;
#ifdef DES
    int c = (x_counter + (DISP_HEIGHT - y_counter)) % 3;
    if (c == 0)
        pixel = 0xff000000 | (pixel << 16);
    else if (c == 1)
        pixel = 0xff000000 | pixel;
    else
        pixel = 0xff000000 | (pixel << 8);
#endif
#ifdef MONO
    pixel = (pixel << 16) | (pixel << 8) | (pixel) | 0xff000000ul;
#endif
    pixels[y * DISP_WIDTH + x] = pixel;
}

void dispsim_reset() {
    x_counter = 0;
    y_counter = 0;
    last_hs = 0;
    memset(localbuf, 0xff, sizeof(localbuf));
}

void dispsim_apply(uint32_t *pixels, const uint8_t gdoe,
        const uint8_t gdclk, const uint8_t gdsp, const uint8_t sdle,
        const uint8_t sdoe, const uint8_t sd, const uint8_t sdce0) {
    // SDLE = Hsync
    // GDSP = ~ Vsync
    // SDCE0 = ~ DE
    uint8_t hs = sdle;
    uint8_t vs = !gdsp;
    uint8_t de = !sdce0;
    static bool line_valid;

    if (!last_hs && hs) {
        x_counter = 0;
        if (vs) {
            y_counter = 0;
            line_valid = false;
            render_copy();
        }
        else {
            if (line_valid)
                y_counter++;
        }
    }

    if (de) {
        dispsim_set_pixel(pixels, x_counter++, y_counter, (sd >> 6) & 0x3);
        dispsim_set_pixel(pixels, x_counter++, y_counter, (sd >> 4) & 0x3);
        dispsim_set_pixel(pixels, x_counter++, y_counter, (sd >> 2) & 0x3);
        dispsim_set_pixel(pixels, x_counter++, y_counter, (sd >> 0) & 0x3);
        line_valid = true;
    }

    last_hs = hs;
}
