// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Anders <anders-code@users.noreply.github.com>

`resetall
`timescale 1ns/1ps
`default_nettype none

`include "sim/utils/tb_assert.vh"

module tb_wait_state ();

import tb_utils::*;

logic clk;
logic rst;
tb_clkgen tb_clkgen_inst( .clk );

logic [15:0]ab;
logic  [7:0]dout;
logic  [7:0]din;
logic       we;
logic       irq;
logic       nmi;
logic       rdy;

cpu_6502 cpu_inst (
  .clk,
  .reset (rst),
  .AB    (ab),
  .DI    (din),
  .DO    (dout),
  .WE    (we),
  .IRQ   (irq),
  .NMI   (nmi),
  .RDY   (rdy)
);

reg [7:0]mem[64*1024];
reg [7:0]memout;
always_ff @(posedge clk) begin
    if (rdy) begin
        if (we)
            mem[ab] <= dout;
        memout <= mem[ab];
    end
end
assign din = rdy ? memout : 8'hxx;

always begin  
     #7 rdy = 1;
    #10 rdy = 0;
    #13;
end

initial begin
    $readmemh(tb_rel_path("../mem-files/basic.mem"), mem, 0, $size(mem)-1);

    if (tb_enable_dumpfile("tb_wait_state.vcd"))
        $dumpvars(0, tb_wait_state);
    #17 rst = 1;
   #100 rst = 0;
        irq = 0;
        nmi = 0;

   #400 wait(cpu_inst.state == cpu_inst.DECODE && rdy);
       @(posedge clk);
        `tb_assert(cpu_inst.PC_temp == 'h0401);
        tb_assert_report;
        $finish(2);
end

endmodule
`resetall
