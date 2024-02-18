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
#include <queue>
#include "spisim.h"

static const int SPI_DIV = 10;
static int spi_divider = 0;
static uint8_t spi_tx;
static uint8_t spi_rx;
static int cs = 1;
static int sck = 1;
static int mosi = 1;
static int bit_counter = 0;
static int byte_counter = 0;
// Current transaction
// There is no multithreading going on in the simulator, so lock is not needed.
// 0x00-0xFF normal data
// 0x100     break (pull CS high)
static std::queue<uint16_t> byte_buf;

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
                if (cs == 0) {
                    printf("RX byte: %02x\n", spi_rx);
                }
                if (byte_buf.empty()) {
                    // Empty, stop
                    cs = 1;
                    spi_tx = 0xff;
                }
                else if (byte_buf.front() == 0x100) {
                    // Requested packet break, stop
                    byte_buf.pop();
                    cs = 1;
                    spi_tx = 0xff;
                }
                else {
                    // Has data, start or continue
                    cs = 0;
                    spi_tx = byte_buf.front();
                    byte_buf.pop();
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
            spi_rx <<= 1;
            spi_rx |= spi_miso & 0x1;
        }
    }
    spi_cs = cs;
    spi_sck = sck;
    spi_mosi = mosi;
}

void spi_write_reg8(uint8_t addr, uint8_t val) {
    byte_buf.push(addr);
    byte_buf.push(val);
    byte_buf.push(0x100);
}

void spi_write_reg16(uint8_t addr, uint16_t val) {
    byte_buf.push(addr);
    byte_buf.push(val >> 8);
    byte_buf.push(val & 0xff);
    byte_buf.push(0x100);
}

void spi_write_bulk(uint8_t addr, uint8_t *buf, int length) {
    byte_buf.push(addr);
    for (int i = 0; i < length; i++) {
        byte_buf.push(buf[i]);
    }
    byte_buf.push(0x100);
}

bool spi_is_busy(void) {
    if (cs == 0)
        return true;
    if (byte_buf.size() > 0)
        return true;
    return false;
}
