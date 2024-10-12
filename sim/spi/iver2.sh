#!/bin/sh -x

TOP="tb_spi_sram"
mkdir -p build/bin
iverilog -g2012 -grelative-include \
    -o "build/bin/i${TOP}" \
    -Wall -DSIM -I../.. \
    ../../rtl/spi*.sv  \
    ../utils/*.sv  \
    "${TOP}.sv"
