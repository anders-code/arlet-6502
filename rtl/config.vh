`ifdef __openlane__
    `ifdef VERILATOR
        // openlane using Verilator for linting
        `define OPENLANE_LINT 1
    `endif
`endif

`ifdef CONFIG_TT
    // Tiny Tapeout config

    // use async reset ff's for ASIC flow
    `define USE_ASYNC_RESET 1

    `ifdef SYNTHESIS
        `define NO_TIMESCALE 1
    `elsif OPENLANE_LINT
        // in this synth-like context, skip timescales too
        `define NO_TIMESCALE 1
    `endif
`else
    // default config

    // use sync reset ff's for FPGA, etc. flow
    `undef USE_ASYNC_RESET

    // use timescales by default
    `undef NO_TIMESCALE
`endif
