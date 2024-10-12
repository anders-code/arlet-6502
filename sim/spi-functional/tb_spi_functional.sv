// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Anders <anders-code@users.noreply.github.com>

`resetall
`timescale 1ns/1ps
`default_nettype none


module tb_spi_functional (
    input wire clk,
    input wire rst
);

tb_clkrst clkrst_inst (.clk, .rst);

import tb_utils::*;

logic [15:0]ab;
logic  [7:0]dout;
logic  [7:0]din;
logic       we;
logic       irq = 0;
logic       nmi = 0;
wire        rdy;

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
    .mem_rdata (din),
    .mem_rdata0 (),
    .mem_rdata_load ()
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

wire [7:0]tc = mem['h0200];
reg [7:0]lasttc = 0;
time lasttm = 100;
time lasttm2 = 0;
int termcnt = 0;
always @(posedge clk) begin
    if (tc != lasttc) begin
        $display("test %2d, time %0d (%0d)", tc, $time/10, ($time-lasttm)/10);
        lasttc  <= tc;
        lasttm  <= $time;
    end
    else if ($time - lasttm2 >= 10_000_000) begin
        $display("         time %0d (%0d)", $time/10, ($time-lasttm)/10);
        lasttm2 <= $time;
    end

    // Arlet's core runs PC one cycle early so PC is 3469+1 when executing 3469
    if (rdy && cpu_inst.PC == 'h3469+1) begin
        // http://forum.6502.org/viewtopic.php?f=8&t=6202#p90723
        // 10 cycles of reset + 6 cycles before executing 0400
        // first cycle where PC == 400+1 and state == DECODE and RDY is 2710:
        //   1st cycle is 41 clks, rest are 44
        //   10 + 41 + 5*44 == 271
        if (termcnt == 0)
            $display("\nSuccess! clocks %0d cycles %0d (ideal 96241364)\n",
                $time/10 - 271, ($time/10 - 271)/44);
        else if (termcnt >= 2)
            $finish(2);

        termcnt <= termcnt + 1;
    end
end

initial begin
    $readmemh(tb_rel_path("../mem-files/6502_functional_test.mem"), mem, 0, $size(mem)-1);
    mem['hfffc] = 8'h00;
    mem['hfffd] = 8'h04;

    if(tb_enable_dumpfile("tb_spi_functional.vcd"))
        $dumpvars(0, tb_spi_functional);
end

endmodule
`resetall
