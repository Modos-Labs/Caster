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
#include <assert.h>

#include <SDL.h>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vcaster.h"

#include "dispsim.h"
#include "srcsim.h"
#include "vramsim.h"
#include "spisim.h"
#include "intapi.h"

#define SIM_STEP 100000
//#define MAX_CYCLES 500000
#define TRACE

constexpr int DISP_FACTOR = 2;

// SDL
SDL_Surface *screen;
SDL_Window *window;
SDL_Renderer *renderer;
SDL_Texture *texture;
SDL_Rect texture_rect;

// Verilator related
Vcaster *core;
VerilatedVcdC *trace;
uint64_t tickcount;

// Legacy function required by some platforms/ versions of Verilator
double sc_time_stamp() { return 0; }

void testmain(void) {
    static int step = 0;
    // This function is called every tick
    switch (step) {
    case 0:
        spi_write_reg8(CSR_CFG_V_FP, 3);
        spi_write_reg8(CSR_CFG_V_SYNC, 1);
        spi_write_reg8(CSR_CFG_V_BP, 2);
        spi_write_reg16(CSR_CFG_V_ACT, 240);
        spi_write_reg8(CSR_CFG_H_FP, 3);
        spi_write_reg8(CSR_CFG_H_SYNC, 1);
        spi_write_reg8(CSR_CFG_H_BP, 2);
        spi_write_reg16(CSR_CFG_H_ACT, 80);
        spi_write_reg8(CSR_CFG_MINDRV, 1);

        // Enable OSD
        spi_write_reg16(CSR_OSD_LEFT, 0);
        spi_write_reg16(CSR_OSD_RIGHT, 256/4);
        spi_write_reg16(CSR_OSD_TOP, 0);
        spi_write_reg16(CSR_OSD_BOTTOM, 128);
        spi_write_reg16(CSR_OSD_ADDR, 0);
        for (int i = 0; i < 4096; i++) {
            spi_write_reg8(CSR_OSD_WR, 0x55);
        }
        spi_write_reg8(CSR_OSD_EN, 1);

        spi_write_reg8(CSR_ENABLE, 1); // Enable refresh
        // Read back status
        spi_write_reg8(CSR_STATUS, 0);
        step = 1;
        break;
    case 1:
        if (!spi_is_busy()) {
            printf("Initialization over SPI done.\n");
            step = 2;
        }
        break;
    case 2:
        /*if (tickcount > 200*1000) {
            printf("Testing clearing\n");
            intapi_redraw(40, 30, 120, 90);
            step = 3;
        }*/
        break;
    // Do more test here
    }
}

void tick(void) {
    // Create local copy of input signals
    uint8_t vin_vsync;
    uint32_t vin_pixel;
    uint8_t vin_valid;
    uint64_t bi_pixel;
    uint8_t bi_valid;
    uint8_t spi_cs;
    uint8_t spi_sck;
    uint8_t spi_mosi;

    // Call simulated modules
    dispsim_apply(
        (uint32_t *)screen->pixels,
        core->epd_gdoe,
        core->epd_gdclk,
        core->epd_gdsp,
        core->epd_sdle,
        core->epd_sdoe,
        core->epd_sd,
        core->epd_sdce0,
        core->dbg_wvfm_tgt
    );
    srcsim_apply(
        vin_vsync,
        vin_pixel,
        vin_valid,
        core->vin_ready
    );
    vramsim_apply(
        core->b_trigger,
        bi_pixel,
        bi_valid,
        core->bi_ready,
        core->bo_pixel,
        core->bo_valid
    );
    spisim_apply(
        spi_cs,
        spi_sck,
        spi_mosi,
        core->spi_miso
    );

    // Posedge
    core->clk = 1;
    core->eval();

    // Apply changed input signals after clock edge
    core->vin_vsync = vin_vsync;
    core->vin_pixel = vin_pixel;
    core->vin_valid = vin_valid;
    core->bi_pixel = bi_pixel;
    core->bi_valid = bi_valid;
    core->spi_cs = spi_cs;
    core->spi_sck = spi_sck;
    core->spi_mosi = spi_mosi;

    // Let combinational changes propagate
    core->eval();
#ifdef TRACE
    trace->dump(tickcount * 10);
#endif

    // Negedge
    core->clk = 0;
    core->eval();
#ifdef TRACE
    trace->dump(tickcount * 10 + 5);
#endif
    tickcount++;

    testmain();
}

void reset(void) {
    core->rst = 1;
    tick();
    tick();
    core->rst = 0;
    dispsim_reset();
    srcsim_reset();
    vramsim_reset();
    spisim_reset();
    core->sys_ready = 1;
}

void render_copy(void) {
    void *texture_pixel;
	int texture_pitch;

	SDL_LockTexture(texture, NULL, &texture_pixel, &texture_pitch);
	memset(texture_pixel, 0, texture_rect.y * texture_pitch);
	uint8_t *pixels = (uint8_t *)texture_pixel + texture_rect.y * texture_pitch;
	uint8_t *src = (uint8_t *)screen->pixels;
	int left_pitch = texture_rect.x * 4;
	int right_pitch = texture_pitch - ((texture_rect.x + texture_rect.w) * 4);
	for (int y = 0; y < texture_rect.h; y++, src += screen->pitch)
	{
		memset(pixels, 0, left_pitch); pixels += left_pitch;
		memcpy(pixels, src, DISP_WIDTH * 4); pixels += DISP_WIDTH * 4;
		memset(pixels, 0, right_pitch); pixels += right_pitch;
	}
	memset(pixels, 0, texture_rect.y * texture_pitch);
	SDL_UnlockTexture(texture);

	SDL_RenderClear(renderer);
	SDL_RenderCopy(renderer, texture, NULL, NULL);
	SDL_RenderPresent(renderer);
}

int main(int argc, char *argv[]) {
    // Initialize testbench
    Verilated::commandArgs(argc, argv);

    core = new Vcaster;
    Verilated::traceEverOn(true);

#ifdef TRACE
    trace = new VerilatedVcdC;
    core->trace(trace, 99);
    trace->open("trace.vcd");
#endif

    // Initialize window
    window = SDL_CreateWindow("Caster",
            SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
            DISP_WIDTH * DISP_FACTOR, DISP_HEIGHT * DISP_FACTOR, SDL_SWSURFACE);
    assert(window);
    renderer = SDL_CreateRenderer(window, -1,
            SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    assert(renderer);
    screen = SDL_CreateRGBSurface(SDL_SWSURFACE, DISP_WIDTH, DISP_HEIGHT, 32,
            0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000);
    assert(screen);
    texture_rect.x = texture_rect.y = 0;
    texture_rect.w = DISP_WIDTH;
    texture_rect.h = DISP_HEIGHT;
    texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
            SDL_TEXTUREACCESS_STREAMING, DISP_WIDTH, DISP_HEIGHT);
    assert(texture);
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

    SDL_FillRect(screen, &texture_rect, 0xFFFFFFFF);

    // Start simulation
    printf("Simulation start.\n");

    reset();

    uint32_t ms_tick = SDL_GetTicks();
    bool running = true;
    while (running) {
        for (int i = 0; i < 10; i++) {
            for (int i = 0; i < SIM_STEP / 10; i++) {
                tick();
            }

            SDL_Event event;
            if (SDL_PollEvent(&event))
            {
                if (event.type == SDL_QUIT)
                {
                    running = false;
                }
            }
        }
        
        uint32_t ms_delta = SDL_GetTicks() - ms_tick;
        char title[50];
        snprintf(title, 50, "Caster Sim (%d kHz)", SIM_STEP / ms_delta);
        SDL_SetWindowTitle(window, title);
        ms_tick = SDL_GetTicks();

#ifdef MAX_CYCLES
        if (tickcount > MAX_CYCLES)
            break;
#endif
    }

    printf("Stop.\n");

#ifdef TRACE
    trace->close();
#endif

    SDL_FreeSurface(screen);
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);

    return 0;
}