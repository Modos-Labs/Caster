TARGET := sim
OBJODIR := obj
RTLDIR := ../rtl

ifeq ($(VERILATOR_ROOT),)
VERILATOR_ROOT ?= $(shell bash -c 'verilator -V|grep VERILATOR_ROOT | head -1 | sed -e " s/^.*=\s*//"')
endif
VROOT := $(VERILATOR_ROOT)
VINCD := $(VROOT)/include
RTLOBJDIR := $(RTLDIR)/obj_dir
RTLOBJ := $(RTLOBJDIR)/Vcaster__ALL.a

CC = g++
CXX = g++
LD = g++
SDL_CONFIG = sdl2-config

LIBS := -lm $(shell $(SDL_CONFIG) --libs)

COMMONFLAGS := \
	$(shell $(SDL_CONFIG) --cflags) \
	-Wall -Og -g

CPPFLAGS := \
	-faligned-new \
	-std=c++17

LDFLAGS :=

INCLUDES += \
	-I. \
	-I$(RTLOBJDIR) \
	-I$(RTLDIR) \
	-I$(VINCD) \
	-I$(VINCD)/vltstd

CSRCS +=

CPPSRCS += \
	./main.cpp \
	./dispsim.cpp \
	./srcsim.cpp \
	verilated.cpp \
	verilated_vcd_c.cpp

OBJS :=	$(CSRCS:%.c=$(OBJODIR)/%.o) \
		$(CPPSRCS:%.cpp=$(OBJODIR)/%.o)

OBJS += $(RTLOBJ)

$(OBJODIR)/%.o: %.c
	@echo [CC] $<
	@mkdir -p $(dir $@)
	@$(CC) $(COMMONFLAGS) $(CCFLAGS) $(INCLUDES) -c -o $@ $<

$(OBJODIR)/%.o: %.cpp
	@echo [CXX] $<
	@mkdir -p $(dir $@)
	@$(CXX) $(COMMONFLAGS) $(CPPFLAGS) $(INCLUDES) -c -o $@ $<

$(OBJODIR)/%.o: $(VINCD)/%.cpp
	@echo [CXX] $<
	@mkdir -p $(dir $@)
	@$(CXX) $(COMMONFLAGS) $(CPPFLAGS) $(INCLUDES) -c -o $@ $<

PHONY += all
all: $(OBJS)
	@$(LD) $(LDFLAGS) $(OBJS) $(LIBS) -o $(TARGET)
	@echo 'all finish'

PHONY += clean
clean:
	rm -rf $(OBJODIR)
	rm -f $(TARGET)
	@echo 'clean finish'

# Declare the contents of the .PHONY variable as phony.  We keep that
# information in a variable so we can use it in if_changed and friends.
.PHONY: $(PHONY)

# Set default target
.DEFAULT_GOAL:= all

