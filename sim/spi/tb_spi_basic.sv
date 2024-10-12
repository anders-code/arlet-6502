// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Anders <anders-code@users.noreply.github.com>

`resetall
`timescale 1ns/1ps
`default_nettype none

`include "sim/utils/tb_assert.vh"

module tb_spi_basic();

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

wire cs_n;
wire mosi;
wire miso;

spi_sram_master spi_sram_master_inst (
    .clk,
    .clkb (~clk),
    .rst,
    .en    (1'b1),
    .enb   (1'b1),
    .cs_n,
    .miso,
    .mosi,
    .mem_addr  ({ 8'b0, ab }),
    .mem_en    (1'b1),
    .mem_wr    (we),
    .mem_wdata (dout),
    .mem_rdy   (rdy),
    .mem_rdata (din)
);

wire [23:0]mem_addr;
wire       mem_en;
wire       mem_wr;
wire  [7:0]mem_wdata;
reg   [7:0]mem_rdata;

spi_sram_slave spi_sram_slave_inst (
    .clk,
    .clkb (~clk),
    .rst,
    .en   (1'b1),
    .enb  (1'b1),
    .cs_n,
    .miso,
    .mosi,
    .mem_addr  (mem_addr),
    .mem_en    (mem_en),
    .mem_wr    (mem_wr),
    .mem_wdata (mem_wdata),
    .mem_rdata (mem_rdata)
);

reg [7:0]mem[64*1024];
always_ff @(posedge clk) begin
    if (mem_en) begin
        if (mem_wr)
            mem[mem_addr[15:0]] <= mem_wdata;
        mem_rdata <= mem[mem_addr[15:0]];
    end
end


initial begin
    $readmemh(tb_rel_path("../mem-files/basic.mem"), mem, 0, $size(mem)-1);

    if (tb_enable_dumpfile("tb_spi_basic.vcd"))
        $dumpvars(0, tb_spi_basic);
    #17 rst = 1;
   #100 rst = 0;
        irq = 0;
        nmi = 0;

   #4000 wait(cpu_inst.state == cpu_inst.DECODE && rdy);
        @(posedge clk);
        `tb_assert(cpu_inst.PC_temp == 'h0401);
        tb_assert_report;
        $finish(2);
end

endmodule
`resetall
