#!/bin/sh -x

TOP="tb_spi_sram"
mkdir -p build/bin
iverilog -g2012 -grelative-include -Wall \
    -o "build/bin/i${TOP}" \
    -I../.. -DCONFIG_TT=1 -DSIM=1 \
    ../../rtl/spi*.sv  \
    ../utils/*.sv  \
    "${TOP}.sv"
