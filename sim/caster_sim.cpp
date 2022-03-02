/*
 *  Caster
 *
 *  caster_sim.cpp: Caster main simulation unit
 *
 *  Copyright (C) 2022  Wenting Zhang <zephray@outlook.com>
 *  Copyright (C) 2015,2017, Gisselquist Technology, LLC
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms and conditions of the GNU General Public License as
 *  published by the Free Software Foundation, either version 3 of the license,
 *  or (at your option) any later version.
 *
 *  This program is distributed in the hope it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 *  more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, see <http://www.gnu.org/licenses/> for a copy.
 */
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <time.h>
#include <unistd.h>
#include <stdint.h>

#include <SDL.h>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vcaster.h"

#define VVAR(A) caster__DOT_ ## A

const int CYCLE_LIMIT = 32768;

static char result_file[127];
static bool trace = false;

class TESTBENCH {
    Vcaster *m_core;
    VerilatedVcdC* m_trace;
    unsigned long  m_tickcount;
public:
    bool m_done;
    bool m_fault;

    TESTBENCH() {
        m_core = new Vcaster;
        Verilated::traceEverOn(true);

        m_done = false;
        m_trace = NULL;

        m_tickcount = 0;
    }

    ~TESTBENCH() {
        if (m_trace) m_trace -> close();
        delete m_core;
        m_core = NULL;
    }

    void opentrace(const char *vcdname) {
        if (!m_trace) {
            m_trace = new VerilatedVcdC;
            m_core -> trace(m_trace, 99);
            m_trace -> open(vcdname);
        }
    }

    void closetrace(void) {
        if (m_trace) {
            m_trace -> close();
            m_trace = NULL;
        }
    }

    void eval(void) {
        m_core -> eval();
    }

    void close(void) {
        m_done = true;
    }

    bool done(void) {
        if ((m_tickcount > CYCLE_LIMIT)) {
                printf("Time Limit Exceeded\n");
                return true;
        }
        if (m_fault)
            return true;
        return m_done;
    }

    virtual void tick(void) {
        m_tickcount++;

        // Make sure we have our evaluations straight before the top
        // of the clock.  This is necessary since some of the 
        // connection modules may have made changes, for which some
        // logic depends.  This forces that logic to be recalculated
        // before the top of the clock.
        eval();
        if (m_trace && trace) m_trace->dump(10*m_tickcount-2);
        m_core -> clk = 1;
        eval();
        if (m_trace && trace) m_trace->dump(10*m_tickcount);
        m_core -> clk = 0;
        eval();
        if (m_trace && trace) m_trace->dump(10*m_tickcount+5);

        /*m_done = m_core -> done;
        m_fault = m_core -> fault;*/
    }

    void reset(void) {
        m_core -> rst = 1;
        tick();
        m_core -> rst = 0;
    }
};

TESTBENCH *tb;

void vb_kill(int v) {
    tb -> close();
    fprintf(stderr, "KILLED!!\n");
    exit(EXIT_SUCCESS);
}

void usage(void) {
    puts("USAGE: caster_sim\n");
}

int main(int argc, char **argv) {
    const char *trace_file = "trace.vcd";
    char window_title[63];

    /*if (argc < 2) {
        usage();
        exit(EXIT_FAILURE);
    }*/
    trace = true;

    Verilated::commandArgs(argc, argv);

    tb = new TESTBENCH();
    tb -> opentrace(trace_file);
    tb -> reset();

    printf("Initialized\n");

    uint32_t sim_tick = 0;
    //uint32_t ms_tick = SDL_GetTicks();
    while (!tb->done()) {
    //while (true) {
        tb -> tick();

        sim_tick++;

        // Get the next event
        /*if (!quiet & (sim_tick % 4096 == 0)) {
            SDL_Event event;
            if (SDL_PollEvent(&event))
            {
                if (event.type == SDL_QUIT)
                {
                    // Break out of the loop on quit
                    break;
                }
            }
            uint32_t ms_delta = SDL_GetTicks() - ms_tick;
            int sim_freq = sim_tick / ms_delta;
            sim_tick = 0;
            sprintf(window_title, "VerilogBoy Sim (%d kHz)", sim_freq);
            tb -> set_title(window_title);
            ms_tick = SDL_GetTicks();
        }*/
    }

    printf("Execution end.\n");
    tb -> closetrace();

    exit(EXIT_SUCCESS);
}
