// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Anders <anders-code@users.noreply.github.com>

`resetall
`timescale 1ns/1ps
`default_nettype none

module tb_clkgen #(
    parameter PERIOD=10,
    parameter CLKQ=1.0
) (
    output wire clk
);

localparam P2 = PERIOD/2.0;

// ensure clock starts without posedge @ time 0 to avoid race conditions
// also ensure the sim handles resets correctly by forcing clk to be invalid
// (1'bx) // @ time 0. this must not propogate after reset.
// first posedge will be @PERIOD ns
reg clki;
always begin
    #P2 clki = 0;
    #P2 clki = 1;
end

assign #CLKQ clk = clki;

endmodule
`resetall
