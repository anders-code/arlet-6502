`ifndef ASYNC

// wish this could be properly parameterized, but the tools won't have *any*
// of it: always @(posedge clk or negedge reset iff SOMEPARAM)

// usage:
//     `include "async_reset.vh"
//     ...
//     always_ff @(posedge clk `ASYNC(negedge rst_n)) begin
//         if (!rst_n)
//             ... 
//
`ifdef USE_ASYNC_RESET
    `define ASYNC(a) or a
`else
    `define ASYNC(a)
`endif

`endif // ASYNC
