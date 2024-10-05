#!/bin/sh -x

TOP="tb_functional"
mkdir -p build/bin
iverilog -g2012 -grelative-include \
    -o "build/bin/i${TOP}" \
    -Wall -DSIM -I../.. \
    ../../rtl/*.v  \
    ../utils/*.sv  \
    "${TOP}.sv"
