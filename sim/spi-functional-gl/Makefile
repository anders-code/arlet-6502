THIS_DIR = $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

BUILD_DIR = $(THIS_DIR)/build
CMAKE_DIR = $(BUILD_DIR)/cmake
BIN_DIR = $(OUT_DIR)/bin

DEFAULT_TARGETS = tb_spi_functional_gl

PHONIES = all configure reconfigure clean really-clean distclean


PDK_ROOT ?= $(HOME)/ttsetup/pdk
PDK_FD_SC_HD_DIR = $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog
PDK_SRCS = sky130_fd_sc_hd.v primitives.v

GATE_DIR ?= $(THIS_DIR)/../../../runs/wokwi/final/pnl
GATE_SRCS  = tt_um_anders_tt_6502.pnl.v

SDF_DIR ?= $(THIS_DIR)/../../../runs/wokwi/final/sdf
ALL_SDF_SRCS ?= $(wildcard $(SDF_DIR)/*/*.sdf)
SDF_SRCS ?= $(notdir $(ALL_SDF_SRCS))

PHONIES += copy-sources clean-sources
UNPHONIES += $(GATE_SRCS) $(PDK_SRCS) $(SDF_SRCS)

ifeq ($(wildcard $(GATE_DIR)/$(GATE_SRCS)),)
$(info Cannot find: $(GATE_DIR:$(THIS_DIR)/%=%)/$(GATE_SRCS))
$(error Sim cannot be built until design is locally hardened)
endif


TARGETS = $(filter-out $(PHONIES) $(UNPHONIES),$(MAKECMDGOALS))
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

$(TARGETS): configure copy-sources
	cmake --build $(CMAKE_DIR) -- $(TARGETS)

clean: clean-sources
	cmake --build $(CMAKE_DIR) -- -t clean

really-clean:
	git clean -dXf .

distclean:
	git clean -dxf .

copy-sources: $(PDK_SRCS) $(GATE_SRCS) $(SDF_SRCS)

clean-sources:
	rm -f $(PDK_SRCS) $(GATE_SRCS) $(SDF_SRCS)

$(GATE_SRCS): %: $(GATE_DIR)/%
	cp -f "$<" "$@"

# fixup pdk sources for vivado sim
# - remove default_nettype
# - remove timescale (for timing sim)
# - patch, if necessary
$(PDK_SRCS): %: $(PDK_FD_SC_HD_DIR)/%
	cp -f "$<" "$@"
	sed -ri -e '/`default_nettype/d' "$@"
	sed -ri -e '/`timescale/d' "$@"
	-patch "$@" "$@.patch"


# fixup .sdf files for vivado sim
# - get rid of VOLTAGE/PROCESS/TEMPERATURE lines
#   (empty middle entry doesn't parse)
# - change DIVIDER from . to /
#   (vivado just silently ignores names with . as the separator)
# - change all . dividers in INTERCONNECT lines from . to /
#   (only change .'s followed by id to avoid decimal numbers)
$(SDF_SRCS): $(ALL_SDF_SRCS)
	cp -f "$(wildcard $(SDF_DIR)/*/$@)" "$@"
	sed -ri -e '/\((VOLTAGE|PROCESS|TEMPERATURE)/d' \
	        -e 's/\(DIVIDER \./(DIVIDER \//' \
	        -e '/\(INTERCONNECT/s/\.([A-Za-z_])/\/\1/g' "$@"

.PHONY: $(PHONIES)
