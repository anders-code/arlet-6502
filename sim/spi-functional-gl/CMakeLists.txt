cmake_minimum_required(VERSION 3.19)

project(arlet-6502)

file(REAL_PATH ${CMAKE_BINARY_DIR}/.. BUILD_DIR)

set(SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(BIN_DIR    ${BUILD_DIR}/bin)
set(LIB_DIR    ${BUILD_DIR}/lib)
set(DATA_DIR   ${BUILD_DIR}/data)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${LIB_DIR})

find_package(verilator 5 HINTS $ENV{VERILATOR_ROOT} REQUIRED)


set(TARGET tb_spi_functional_gl)
set(PREFIX V${TARGET})

add_executable(${TARGET} ../utils/verilator_main.cpp)

verilate(${TARGET}
    TOP_MODULE     ${TARGET}
    PREFIX         ${PREFIX}
    THREADS        0
    TRACE_FST      1
    OPT_SLOW       -O3
    OPT_FAST       -O3
    OPT_GLOBAL     -O3
    VERILATOR_ARGS
        --relative-includes
        -DFUNCTIONAL=1 -DUSE_POWER_PINS=1
        -Wall -Wpedantic -Wno-fatal -Werror-USERFATAL -Werror-USERERROR
        --x-assign fast --x-initial fast --trace-underscore
    SOURCES
        cfg.vlt
        primitives_behav.sv
        sky130_fd_sc_hd.v
        tt_um_anders_tt_6502.pnl.v
        ../../rtl/cfg.vlt
        ../../rtl/spi_sram_slave.sv
        ../utils/cfg.vlt
        ../utils/tb_utils.sv
        ../utils/tb_clkrst.sv
        tb_spi_functional_gl.sv
)

target_compile_definitions(${TARGET} PRIVATE VTB=${PREFIX})
target_compile_options(${TARGET} PRIVATE -g3)
