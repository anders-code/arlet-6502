THIS_DIR = $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

BUILD_DIR = $(THIS_DIR)/build
CMAKE_DIR = $(BUILD_DIR)/cmake
BIN_DIR = $(OUT_DIR)/bin

DEFAULT_TARGETS = tb_spi_functional tb_spi_functional_nl

PHONIES = all configure reconfigure clean

TARGETS = $(filter-out $(PHONIES),$(MAKECMDGOALS))
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

clean:
	cmake --build $(CMAKE_DIR) -- -t clean

.PHONY: $(PHONIES)
