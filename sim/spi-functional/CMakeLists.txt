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


set(TARGET tb_spi_functional)
set(PREFIX V${TARGET})

file(GLOB RTL_SOURCES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    ../../rtl/*.sv
)
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
        --relative-includes -DSIM=1
        -Wall -Wpedantic -Wno-fatal -Werror-USERFATAL -Werror-USERERROR
        --x-assign fast --x-initial fast --trace-underscore
    SOURCES
        cfg.vlt
        ../../rtl/cfg.vlt
        ${RTL_SOURCES}
        ../utils/cfg.vlt
        ../utils/tb_utils.sv
        ../utils/tb_clkrst.sv
        tb_spi_functional.sv
)

target_compile_definitions(${TARGET} PRIVATE VTB=${PREFIX})
target_compile_options(${TARGET} PRIVATE -g3)


set(TARGET tb_spi_functional_nl)
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
        --relative-includes -DSIM=1
        -DFUNCTIONAL=1 -DUNIT_DELAY=
        -Wall -Wpedantic -Wno-fatal -Werror-USERFATAL -Werror-USERERROR
        --x-assign fast --x-initial fast --trace-underscore
    SOURCES
        cfg.vlt
        ../../rtl/cfg.vlt
        ../../rtl/spi_sram_slave.sv
        primitives_v.v
        sky130_fd_sc_hd.v
        tt_um_anders_tt_6502.nl.v
        ../utils/cfg.vlt
        ../utils/tb_utils.sv
        ../utils/tb_clkrst.sv
        tb_spi_functional_nl.sv
)

target_compile_definitions(${TARGET} PRIVATE VTB=${PREFIX})
target_compile_options(${TARGET} PRIVATE -g3)
