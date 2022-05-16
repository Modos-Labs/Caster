################################################################################
##
## Filename:  Makefile
##
## Project:	  Caster
##
################################################################################
##
## Copyright (C) 2022, Wenting Zhang
## Copyright (C) 2015-2017, Gisselquist Technology, LLC
##
## This program is free software (firmware): you can redistribute it and/or
## modify it under the terms of  the GNU General Public License as published
## by the Free Software Foundation, either version 3 of the License, or (at
## your option) any later version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
## FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
## for more details.
##
## You should have received a copy of the GNU General Public License along
## with this program.  If not, see <http://www.gnu.org/licenses/> for a copy.
##
################################################################################

CXX	:= g++
OBJDIR  := obj_pc
RTLD	:= ../rtl
ifeq ($(VERILATOR_ROOT),)
VERILATOR_ROOT ?= $(shell bash -c 'verilator -V|grep VERILATOR_ROOT | head -1 | sed -e " s/^.*=\s*//"')
endif
VROOT   := $(VERILATOR_ROOT)
GFXFLAGS:= $(shell pkg-config sdl2 --cflags)
GFXLIBS := $(shell pkg-config sdl2 --cflags --libs)
FLAGS	:= -Wall -Og -g -faligned-new -std=c++11
VINCD   := $(VROOT)/include
INCS	:= -I$(RTLD)/obj_dir/ -I$(RTLD) -I$(VINCD) -I$(VINCD)/vltstd
OBJS    := $(OBJDIR)/caster_sim.o
VOBJDR	:= $(RTLD)/obj_dir
VOBJS   := $(OBJDIR)/verilated.o $(OBJDIR)/verilated_vcd_c.o
PROGRAMS := caster_sim
all:	$(PROGRAMS)

%.o: $(OBJDIR)/%.o
$(OBJDIR)/%.o: %.cpp
	$(mk-objdir)
	$(CXX) $(FLAGS) $(GFXFLAGS) $(INCS) -c $< -o $@

$(OBJDIR)/%.o: $(VINCD)/%.cpp
	$(mk-objdir)
	$(CXX) $(FLAGS) $(INCS) -c $< -o $@

caster_sim: $(OBJS) $(VOBJS) $(VOBJDR)/Vcaster__ALL.a
	$(CXX) $(GFXLIBS) $(INCS) $^ $(VOBJDR)/Vcaster__ALL.a $(GFXLIBS) -o $@

define	mk-objdir
	@bash -c "if [ ! -e $(OBJDIR) ]; then mkdir -p $(OBJDIR); fi"
endef

.PHONY: clean
clean:
	rm -f *.vcd
	rm -rf $(OBJDIR)/
	rm -f $(PROGRAMS)
	rm -f *.o
