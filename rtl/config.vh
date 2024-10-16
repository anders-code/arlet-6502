`ifdef CONFIG_TT
    // Tiny Tapeout config

    // use async reset ff's for ASIC flow
    `define USE_ASYNC_RESET 1

    `ifdef SYNTHESIS
        `define NO_TIMESCALE 1
    `elsif __openlane__
        // openlane uses Verilator for linting
        // in this synth-like context, skip timescales
        `ifdef VERILATOR
            `define NO_TIMESCALE 1
        `endif
    `endif
`else
    // default config

    // use sync reset ff's for FPGA-like flow
    `undef USE_ASYNC_RESET

    // use timescales by default
    `undef NO_TIMESCALE
`endif
