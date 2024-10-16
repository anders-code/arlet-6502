THIS_DIR = $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

BUILD_DIR = $(THIS_DIR)/build
CMAKE_DIR = $(BUILD_DIR)/cmake
BIN_DIR = $(OUT_DIR)/bin

DEFAULT_TARGETS = tb_spi_functional_gl

PHONIES = all configure reconfigure clean really-clean distclean


PDK_ROOT ?= $(HOME)/ttsetup/pdk
PDK_FD_SC_HD_DIR = $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog
PDK_SRCS = sky130_fd_sc_hd.v

GATE_DIR ?= $(THIS_DIR)/../../../runs/wokwi/final/pnl
GATE_SRCS  = tt_um_anders_tt_6502.pnl.v

PHONIES += copy-sources clean-sources
MAKE_TARGETS += $(GATE_SRCS) $(PDK_SRCS)


TARGETS = $(filter-out $(MAKE_TARGETS) $(PHONIES),$(MAKECMDGOALS))
ifeq ($(TARGETS),)
    TARGETS = $(DEFAULT_TARGETS)
endif

ifeq ($(DEBUG),1)
    CMAKE_DEBUG = -DCMAKE_BUILD_TYPE=Debug --fresh
endif
ifeq ($(DEBUG),0)
    CMAKE_DEBUG = --fresh
endif

ifeq ($(VERILATOR_ROOT),)
    ifneq ($(wildcard $(THIS_DIR)/verilator/bin/verilator_bin*),)
        export VERILATOR_ROOT=$(THIS_DIR)/verilator
    endif
endif

all: $(DEFAULT_TARGETS)

configure: $(CMAKE_DIR)/CMakeCache.txt

reconfigure $(CMAKE_DIR)/CMakeCache.txt:
	cmake -B $(CMAKE_DIR) -S $(THIS_DIR) -GNinja $(CMAKE_DEBUG) || rm -f $(CMAKE_DIR)/CMakeCache.txt

$(TARGETS): configure
	cmake --build $(CMAKE_DIR) -- $(TARGETS)

clean: clean-sources
	cmake --build $(CMAKE_DIR) -- -t clean

really-clean:
	git clean -dXf .

distclean:
	git clean -dxf .

copy-sources: $(PDK_SRCS) $(GATE_SRCS)

clean-sources:
	rm -f $(PDK_SRCS) $(GATE_SRCS)

$(GATE_SRCS): %: $(GATE_DIR)/%
	cp -f "$<" "$@"

$(PDK_SRCS): %: $(PDK_FD_SC_HD_DIR)/%
	cp -f "$<" "$@"
	sed -ri -e '/`default_nettype/d' "$@"
	patch "$@" "$@.patch"

.PHONY: $(PHONIES)
