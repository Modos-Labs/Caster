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
#include "spisim.h"

static const int SPI_DIV = 10;
static int spi_divider = 0;
static uint8_t spi_tx;
static int cs = 1;
static int sck = 1;
static int mosi = 1;
static int bit_counter = 0;
static int byte_counter = 0;
// Current transaction
static int byte_count = 0;
static uint8_t byte_buf[8192];

uint8_t spi_get_next_bytes(uint8_t *buf);

void spisim_reset() {
    spi_divider = SPI_DIV;
    cs = 1;
    sck = 1;
    bit_counter = 0;
    byte_counter = 0;
}

void spisim_apply(uint8_t &spi_cs, uint8_t &spi_sck, uint8_t &spi_mosi,
        const uint8_t spi_miso) {
    spi_divider--;
    if (spi_divider == 0) {
        spi_divider = SPI_DIV;
        if (sck == 1) {
            // negedge
            sck = 0;
            if (bit_counter == 0) {
                cs = 0;
                if (byte_counter == 0) {
                    byte_count = spi_get_next_bytes(byte_buf);
                }
                spi_tx = byte_buf[byte_counter];
                if (byte_counter == byte_count) {
                    cs = 1;
                    byte_counter = 0;
                    spi_tx = 0xff;
                }
                else {
                    byte_counter ++;
                }
            }
            mosi = (spi_tx >> 7) & 0x01;
            spi_tx <<= 1;
            bit_counter ++;
            if (bit_counter == 8) bit_counter = 0;
        }
        else {
            // posedge
            sck = 1;
        }
    }
    spi_cs = cs;
    spi_sck = sck;
    spi_mosi = mosi;
}

uint8_t spi_get_next_bytes(uint8_t *buf) {
    static int seq = 0;
    seq++;
    if (seq == 1) {
        // Try write something
        byte_buf[0] = 0x01;
        byte_buf[1] = 0x02;
        byte_buf[2] = 0x34;
        return 3;
    }
    else {
        return 0;
    }
}
