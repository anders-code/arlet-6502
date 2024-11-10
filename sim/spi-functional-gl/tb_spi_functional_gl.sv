// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Anders <anders-code@users.noreply.github.com>

`resetall
`timescale 1ns/1ps
`default_nettype none


module tb_spi_functional_gl (
    input wire clk,
    input wire rst
);

tb_clkrst clkrst_inst (.clk, .rst);

import tb_utils::*;

wire  [7:0] ui_in;
wire  [7:0] uo_out;
wire  [7:0] uio_in;
wire  [7:0] uio_out;
wire  [7:0] uio_oe;

wire VPWR = 1;
wire VGND = 0;

tt_um_anders_tt_6502 tt_6502_inst (
    .clk,
    .rst_n (!rst),
    .VPWR,
    .VGND,
    .ena   (1'b1),
    .ui_in,
    .uo_out,
    .uio_in,
    .uio_out,
    .uio_oe
);

wire cs_n = uio_out[0];
wire mosi = uio_out[1];
wire miso;
assign uio_in[7:3] = 0;
assign uio_in[2] = miso;
assign uio_in[1:0] = 0;

logic       irq = 0;
logic       nmi = 0;
assign ui_in[5:0] = 6'b00_0011;
assign ui_in[6] = irq;
assign ui_in[7] = nmi;

wire [23:0]mem_addr;
wire       mem_en;
wire       mem_wr;
wire  [7:0]mem_wdata;
reg   [7:0]mem_rdata;

spi_sram_slave #(
    .CS_DELAY (0)
) spi_sram_slave_inst (
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

wire [15:0]PC = { tt_6502_inst.\spi_cpu_inst.cpu_inst.PC[15] , tt_6502_inst.\spi_cpu_inst.cpu_inst.PC[14] , tt_6502_inst.\spi_cpu_inst.cpu_inst.PC[13] , tt_6502_inst.\spi_cpu_inst.cpu_inst.PC[12] ,
              tt_6502_inst.\spi_cpu_inst.cpu_inst.PC[11] , tt_6502_inst.\spi_cpu_inst.cpu_inst.PC[10] , tt_6502_inst.\spi_cpu_inst.cpu_inst.PC[9]  , tt_6502_inst.\spi_cpu_inst.cpu_inst.PC[8] ,
              tt_6502_inst.\spi_cpu_inst.cpu_inst.PC[7]  , tt_6502_inst.\spi_cpu_inst.cpu_inst.PC[6]  , tt_6502_inst.\spi_cpu_inst.cpu_inst.PC[5]  , tt_6502_inst.\spi_cpu_inst.cpu_inst.PC[4] ,
              tt_6502_inst.\spi_cpu_inst.cpu_inst.PC[3]  , tt_6502_inst.\spi_cpu_inst.cpu_inst.PC[2]  , tt_6502_inst.\spi_cpu_inst.cpu_inst.PC[1]  , tt_6502_inst.\spi_cpu_inst.cpu_inst.PC[0] };

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
    else if ($time - lasttm2 >= 1_000_000) begin
        $display("         time %0d (%0d)", $time/10, ($time-lasttm)/10);
        lasttm2 <= $time;
    end

    // Arlet's core runs PC one cycle early so PC is 3469+1 when executing 3469
    if (tt_6502_inst.\spi_cpu_inst.cache_inst.cpu_rdy && PC == 'h3469+1) begin
        // http://forum.6502.org/viewtopic.php?f=8&t=6202#p90723
        // 10+3 cycles of reset + 6 cycles before executing 0400
        // first cycle where PC == 400+1 and state == DECODE and RDY is 2710:
        //   13 + 6*41 == 259
        if (termcnt == 0)
            $display("\nSuccess! clocks %0d cycles %0d (ideal 96241364)\n",
                $time/10 - 259, ($time/10 - 259)/41);
        else if (termcnt >= 2)
            $finish(2);

        termcnt <= termcnt + 1;
    end
end

initial begin
    $readmemh(tb_rel_path("../mem-files/6502_functional_test.mem"), mem, 0, $size(mem)-1);
    mem['hfffc] = 8'h00;
    mem['hfffd] = 8'h04;
    
    if(tb_enable_dumpfile("tb_spi_functional_gl.vcd"))
        $dumpvars(0, tb_spi_functional_gl);
end

endmodule
`resetall
