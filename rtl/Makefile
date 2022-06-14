################################################################################
## Filename: Makefile
## Engineer: Wenting Zhang
##
## Project: Caster
## Description:
##   Makefile for building the Caster with Verilator. 
##   Use Xilinx ISE or Quartus for FPGA build.
################################################################################

all: caster

VOBJ := obj_dir
CXX   := g++
FBDIR := .

.PHONY: all
caster: $(VOBJ)/Vcaster__ALL.a

SUBMAKE := $(MAKE) --no-print-directory --directory=$(VOBJ) -f
ifeq ($(VERILATOR_ROOT),)
VERILATOR := verilator
else
VERILATOR := $(VERILATOR_ROOT)/bin/verilator
endif
VFLAGS := -Wall -Wno-fatal -MMD --trace -cc 

SRC := caster.v dithering.v pixel_processing.v

$(VOBJ)/Vcaster__ALL.a: $(VOBJ)/Vcaster.cpp $(VOBJ)/Vcaster.h
$(VOBJ)/Vcaster__ALL.a: $(VOBJ)/Vcaster.mk
$(VOBJ)/Vcaster.h $(VOBJ)/Vcaster.cpp $(VOBJ)/Vcaster.mk: $(SRC)

$(VOBJ)/V%.cpp $(VOBJ)/V%.h $(VOBJ)/V%.mk: $(FBDIR)/%.v
	$(VERILATOR) $(VFLAGS) $*.v

$(VOBJ)/V%.cpp: $(VOBJ)/V%.h
$(VOBJ)/V%.mk:  $(VOBJ)/V%.h
$(VOBJ)/V%.h: $(FBDIR)/%.v

$(VOBJ)/V%__ALL.a: $(VOBJ)/V%.mk
	$(SUBMAKE) V$*.mk

.PHONY: clean
clean:
	rm -rf $(VOBJ)/*.mk
	rm -rf $(VOBJ)/*.cpp
	rm -rf $(VOBJ)/*.h
	rm -rf $(VOBJ)/
