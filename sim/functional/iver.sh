#!/bin/sh -x

TOP="tb_functional"
mkdir -p build/bin
iverilog -g2012 -grelative-include -Wall \
    -o "build/bin/i${TOP}" \
    -I../.. -DCONFIG_TT=1 -DSIM=1 \
    ../../rtl/[ca]*.sv  \
    ../utils/*.sv  \
    "${TOP}.sv"
