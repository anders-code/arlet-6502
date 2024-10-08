`ifndef TS_UNIT
    `define TS_UNIT 1ns
`endif
`ifndef TS_PREC
    `define TS_PREC 1ps
`endif

`ifndef NO_TIMESCALE
    `timescale `TS_UNIT/`TS_PREC
`endif
