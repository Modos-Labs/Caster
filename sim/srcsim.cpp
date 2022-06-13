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
#include "srcsim.h"
#include "dispsim.h"

static uint8_t pixels[DISP_WIDTH * DISP_HEIGHT];
static int x_counter;
static int y_counter;
static int frame_counter;

void srcsim_next_frame() {
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
        // Image input is Y4 for now, will be Y8 soon
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
                printf("VIN FS\n");
            }
        }
    }
}