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

#define MAX_CYCLES 100000

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

void tick() {
    dispsim_apply(
        (uint32_t *)screen->pixels,
        core->epd_gdoe,
        core->epd_gdclk,
        core->epd_gdsp,
        core->epd_sdle,
        core->epd_sdoe,
        core->epd_sd,
        core->epd_sdce0
    );
    srcsim_apply(
        core->vin_vsync,
        core->vin_pixel,
        core->vin_valid,
        core->vin_ready
    );
    core->clk = 1;
    core->eval();
    trace->dump(tickcount * 10);
    core->clk = 0;
    core->eval();
    trace->dump(tickcount * 10 + 5);
    tickcount++;
}

void reset() {
    core->rst = 1;
    tick();
    core->rst = 0;
    dispsim_reset();
    srcsim_reset();
}

void render_copy() {
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

#ifdef MAX_CYCLES
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

    SDL_FillRect(screen, &texture_rect, 0xFF0000FF);

    // Start simulation
    printf("Simulation start.\n");

    reset();

    while (true) {
        tick();
#ifdef MAX_CYCLES
        if (tickcount > MAX_CYCLES)
            break;
#endif
    }

    printf("Stop.\n");

    if (trace)
        trace->close();

    SDL_FreeSurface(screen);
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);

    return 0;
}