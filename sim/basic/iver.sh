#!/bin/sh -x

TOP="tb_basic"
mkdir -p build/bin
iverilog -g2012 -grelative-include \
    -o "build/bin/i${TOP}" \
    -Wall -DSIM -I../.. \
    ../../rtl/[ca]*.sv  \
    ../utils/*.sv  \
    "${TOP}.sv"
