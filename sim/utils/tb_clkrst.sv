// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Anders <anders-code@users.noreply.github.com>

`resetall
`timescale 1ns/1ps
`default_nettype none

module tb_clkrst #(
    parameter PERIOD=10,
    parameter CLKQ=1.0,
    parameter RESET_CYCLES=5,
    parameter RESET_PHASE=0.4
) (
`ifndef VERILATOR
    output wire clk,
    output wire rst
`else
    input wire clk,
    input wire rst
`endif
);

`ifndef VERILATOR

localparam P2 = PERIOD/2.0;

// ensure clock starts without posedge @ time 0 to avoid race conditions
// also ensure the sim handles resets correctly by forcing clk to be invalid
// (1'bx) // @ time 0. this must not propogate after reset.
// first posedge will be @PERIOD ns
logic clki;
always begin
    #P2 clki = 0;
    #P2 clki = 1;
end
assign #CLKQ clk = clki;

logic rsti;
initial begin
    #(PERIOD*RESET_CYCLES - PERIOD*RESET_PHASE); // e.g. @46
    rsti = 1;
    #(PERIOD*RESET_CYCLES); // e.g. @96
    rsti = 0;
end
assign rst = rsti;

`endif // VERILATOR

endmodule
`resetall
