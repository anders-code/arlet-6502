// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Anders <anders-code@users.noreply.github.com>

`resetall
`default_nettype none

`include "config.vh"
`include "timescale.vh"

module reset_sync (
    input  wire clk,
    input  wire arst_n,
    output wire rst
);

reg rst1, rst2, rst3;
always_ff @(posedge clk or negedge arst_n) begin
    if (!arst_n) begin
        rst1 <= 1;
        rst2 <= 1;
        rst3 <= 1;
    end
    else begin
        rst1 <= 0;
        rst2 <= rst1;
        rst3 <= rst2;
    end
end

assign rst = rst3;

endmodule
`resetall
