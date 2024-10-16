#!/bin/sh -x

TOP="tb_spi_functional_gl"

mkdir -p build/bin
iverilog -g2012 -grelative-include -Wall -Wno-timescale -Wno-portbind \
    -o "build/bin/i${TOP}" \
    -I../.. -DFUNCTIONAL=1 -DUSE_POWER_PINS=1 \
    ../../rtl/spi_sram_slave.sv  \
    ../utils/*.sv  \
    primitives_behav.sv \
    sky130_fd_sc_hd.v \
    tt_um_anders_tt_6502.pnl.v \
    "${TOP}.sv"
