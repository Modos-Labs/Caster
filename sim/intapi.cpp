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
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <assert.h>
#include "intapi.h"
#include "spisim.h"

static UPDATE_MODE current_mode;
static size_t last_update;
static size_t last_update_duration;
static uint8_t waveform_frames;

static size_t intapi_get_time_ms() {

}

static void intapi_delay_ms(size_t ms) {

}

static void intapi_wait() {
    size_t time_diff = intapi_get_time_ms() - last_update;
    if (time_diff < last_update_duration) {
        size_t time_to_wait = last_update_duration - time_diff;
        intapi_delay_ms(time_to_wait);
    }
}

static uint8_t intapi_get_mode_update_frames(UPDATE_MODE mode) {
    switch (mode) {
    case UM_MANUAL_LUT_NO_DITHER:
    case UM_MANUAL_LUT_ERROR_DIFFUSION:
    case UM_AUTO_LUT_NO_DITHER:
    case UM_AUTO_LUT_ERROR_DIFFUSION:
        return waveform_frames;
    case UM_FAST_MONO_NO_DITHER:
    case UM_FAST_MONO_ORDERED:
    case UM_FAST_MONO_ERROR_DIFFUSION:
        return;
    case UM_FAST_GREY:
        return;
    default:
        assert(0);
        return 0;
    }
}

void intapi_init(void) {
    current_mode = UM_AUTO_LUT_NO_DITHER; // Need to sync with the RTL code
    last_update = intapi_get_time_ms();
    last_update_duration = 0;
    waveform_frames = 38; // Need to sync with the RTL code
}

void intapi_load_waveform(uint8_t *wvfm, uint8_t frames) {
    intapi_wait();
    spi_wrtte_reg8(CSR_LUTFRAME, 0); // Reset value before loading
    spi_write_reg16(CSR_LUTADDR, 0);
    spi_write_bulk(CSR_LUTWR, wvfm, WVFM_SIZE);
    waveform_frames = frames;
}

void intapi_redraw(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1) {
    intapi_wait();
    spi_write_reg16(CSR_OPLEFT, x0);
    spi_write_reg16(CSR_OPTOP, y0);
    spi_write_reg16(CSR_OPRIGHT, x1);
    spi_write_reg16(CSR_OPBOTTOM, y1);
    spi_write_reg8();
}

void intapi_setmode(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1,
        UPDATE_MODE mode) {
    intapi_wait();
    // 
}