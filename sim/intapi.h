//
// Caster simulator
// Copyright 2023 Wenting Zhang
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
#pragma once

// Register map
#define CSR_LUTFRAME        0
#define CSR_LUTADDR_HI      1
#define CSR_LUTADDR_LO      2
#define CSR_LUTWR           3
#define CSR_OPLEFT_HI       4
#define CSR_OPLEFT_LO       5
#define CSR_OPRIGHT_HI      6
#define CSR_OPRIGHT_LO      7
#define CSR_OPTOP_HI        8
#define CSR_OPTOP_LO        9
#define CSR_OPBOTTOM_HI     10
#define CSR_OPBOTTOM_LO     11
#define CSR_OPPARAM         12
#define CSR_OPCMD           13
// Alias for 16bit registers
#define CSR_LUTADDR     CSR_LUTADDR_HI
#define CSR_OPLEFT      CSR_OPLEFT_HI
#define CSR_OPRIGHT     CSR_OPRIGHT_HI
#define CSR_OPTOP       CSR_OPTOP_HI
#define CSR_OPBOTTOM    CSR_OPBOTTOM_HI

#define WVFM_SIZE       (4*1024)

#define FRAME_RATE_HZ   (60)

typedef enum {
    UM_MANUAL_LUT_NO_DITHER = 0,
    UM_MANUAL_LUT_ERROR_DIFFUSION = 1,
    UM_FAST_MONO_NO_DITHER = 2,
    UM_FAST_MONO_ORDERED = 3,
    UM_FAST_MONO_ERROR_DIFFUSION = 4,
    UM_FAST_GREY = 5,
    UM_AUTO_LUT_NO_DITHER = 6,
    UM_AUTO_LUT_ERROR_DIFFUSION = 7
} UPDATE_MODE;

void intapi_init(void);
void intapi_load_waveform(uint8_t *wvfm, uint8_t frames);
void intapi_redraw(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1);
void intapi_setmode(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1,
        UPDATE_MODE mode);
