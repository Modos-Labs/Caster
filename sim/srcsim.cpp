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
#include "srcsim.h"
#include "dispsim.h"
#include "stb_image.h"
#include "stb_image_resize.h"

// Only MSB is used
static uint8_t pixels[DISP_WIDTH * DISP_HEIGHT];
static int x_counter;
static int y_counter;
static int frame_counter;

void print_buffer(uint8_t *buf, size_t bytes) {
    for (int i = 0; i < bytes / 16; i++) {
        for (int j = 0; j < 16; j++) {
            printf("%02x ", buf[i*16+j]);
        }
        printf("\n");
    }
}

static uint8_t rgb2y(uint32_t r, uint32_t g, uint32_t b, int x, int y) {
#ifdef DES
    int c = (x + (DISP_HEIGHT - y)) % 3;
    if (c == 0)
        return r;
    else if (c == 1)
        return b;
    else
        return g;
#endif
#ifdef MONO
    r = r >> 4;
    g = g >> 3;
    b = b >> 4;
    uint32_t y = r + g + b;
    return y << 2;
#endif
}

void srcsim_next_frame() {
#if 0 // Bouncing box
    static int x = 0, y = 0;
    static int dir = 0;
    memset(pixels, 0xff, DISP_WIDTH * DISP_HEIGHT);
    bool xright = (x == DISP_WIDTH - 21);
    bool ydown = (y == DISP_HEIGHT - 21);
    bool yup = (y == 0);
    bool xleft = (x == 0);
    if (dir == 0) {
        // Right down
        if (ydown) dir = 1; // right up
        if (xright) dir = 2; // left down
        if (ydown && xright) dir = 3;
    }
    else if (dir == 1) {
        // Right up
        if (yup) dir = 0; // right down
        if (xright) dir = 3; // left up
        if (yup && xright) dir = 2;
    }
    else if (dir == 2) {
        // Left down
        if (ydown) dir = 3; // left up
        if (xleft) dir = 0; // right down
        if (ydown && xleft) dir = 1;
    }
    else if (dir == 3) {
        // Left up
        if (yup) dir = 2; // left down
        if (xleft) dir = 1; // right up
        if (yup && xleft) dir = 0;
    }

    if (dir == 0) {
        // Right down
        x++; y++;
    }
    else if (dir == 1) {
        // Right up
        x++; y--;
    }
    else if (dir == 2) {
        // Left down
        x--; y++;
    }
    else if (dir == 3) {
        // Left up
        x--; y--;
    }
    for (int i = y; i < y + 20; i++) {
        for (int j = x; j < x + 20; j++) {
            pixels[i * DISP_WIDTH + j] = 0x00;
        }
    }
    frame_counter++;
#endif
#if 1 // Image source
    static int initial_frame = 1;
    if (!initial_frame)
        return;
    int x, y, n;
    uint8_t *data = stbi_load("test1.jpg", &x, &y, &n, 0);
    printf("Input image size %d x %d (%d channels)\n", x, y, n);
    uint8_t *scaled = (uint8_t *)calloc(1, DISP_WIDTH * DISP_HEIGHT * n);
    float scalex, scaley;
    scalex = (float)DISP_WIDTH / (float)x;
    scaley = (float)DISP_HEIGHT / (float)y;
    // Fit the image into destination size keeping aspect ratio
    int outh, outw, outstride, outoffset;
    if (scalex > scaley) {
        outh = DISP_HEIGHT;
        outw = x * scaley;
        outoffset = ((DISP_WIDTH - outw) / 2) * n;
        outstride = x * n;
    }
    else {
        outw = DISP_WIDTH;
        outh = y * scalex;
        outoffset = ((DISP_HEIGHT - outh) / 2) * n * DISP_WIDTH;
        outstride = 0;
    }
    stbir_resize_uint8(data, x, y, 0, scaled + outoffset, outw, outh, outstride, n);
    free(data);
    uint8_t *rdptr = scaled;
    uint8_t *wrptr = pixels;
    if (n == 4) {
        for (int y = 0; y < DISP_HEIGHT; y++) {
            for (int x = 0; x < DISP_WIDTH; x++) {
                uint32_t r = *rdptr++;
                uint32_t g = *rdptr++;
                uint32_t b = *rdptr++;
                uint32_t a = *rdptr++;
                uint32_t yy = rgb2y(r, g, b, x, y);
                *wrptr++ = yy;
            }
        }
    }
    else if (n == 3) {
        for (int y = 0; y < DISP_HEIGHT; y++) {
            for (int x = 0; x < DISP_WIDTH; x++) {
                uint32_t r = *rdptr++;
                uint32_t g = *rdptr++;
                uint32_t b = *rdptr++;
                uint32_t yy = rgb2y(r, g, b, x, y);
                *wrptr++ = yy;
            }
        }
    }
    else if (n == 1) {
        memcpy(wrptr, rdptr, DISP_WIDTH * DISP_HEIGHT);
    }
    free(scaled);
    initial_frame = 0;
#endif
}

void srcsim_reset() {
    x_counter = 0;
    y_counter = 0;
    srcsim_next_frame();
}

void srcsim_apply(uint8_t &vsync, uint16_t &pixel, uint8_t &valid,
        const uint8_t ready) {
    vsync = (y_counter == 0) ? 1 : 0;
    valid = 1;
    if (ready) {
        uint32_t output = 0;
        for (int i = 0; i < 4; i++) {
            uint32_t p = pixels[y_counter * DISP_WIDTH + x_counter++];
            p = p >> 4;
            p = p << (3 - i) * 4;
            output |= p;
        }
        pixel = output;

        if (x_counter == DISP_WIDTH) {
            x_counter = 0;
            y_counter++;
            if (y_counter == DISP_HEIGHT) {
                y_counter = 0;
                srcsim_next_frame();
            }
        }
    }
}