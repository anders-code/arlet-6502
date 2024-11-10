// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Anders <anders-code@users.noreply.github.com>

`resetall
`timescale 1ns/1ps
`default_nettype none


module tb_spi_functional (
    input wire clk,
    input wire rst
);

//localparam IODELAY = 3;
//localparam IODELAY = 8;
//localparam IODELAY = 13;
localparam IODELAY = 0;

tb_clkrst clkrst_inst (.clk, .rst);

import tb_utils::*;


wire cs_n;
wire mosi;
wire miso;
wire sync;

logic [7:0]gpin = 8'b0000_0011;
wire  [7:0]gpout;
logic [3:0]gpio_in = 4'b0;
wire  [3:0]gpio_oe;
wire  [3:0]gpio_out;

logic miso_delay;
`ifndef VERILATOR
    always @* begin
        miso_delay <= #IODELAY miso;
    end
`else
    logic miso_delay1;
    logic miso_delay2;
    logic miso_delay3;

    if (IODELAY >= 5)
        always @(posedge clk) begin
            miso_delay1 <= miso;
        end
    else
        assign miso_delay1 = miso;

    if (IODELAY >= 10)
        always @(negedge clk) begin
            miso_delay2 <= miso_delay1;
        end
    else
        assign miso_delay2 = miso_delay1;

    if (IODELAY >= 15)
        always @(posedge clk) begin
            miso_delay3 <= miso_delay2;
        end
    else
        assign miso_delay3 = miso_delay2;
    assign miso_delay = miso_delay3;
`endif

spi_cpu_6502 spi_cpu_inst (
    .clk,
    .arst_n (~rst),
    .nmi    (1'b0),
    .irq    (1'b0),
    .cs_n,
    .mosi,
    .miso   (miso_delay),
    .sync,
    .gpin,
    .gpout,
    .gpio_in,
    .gpio_oe,
    .gpio_out
);

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
reg [7:0]lasttc = 0;
time lasttm = 100;
time lasttm2 = 0;
int termcnt = 0;

reg [15:0]capAB;
reg  [7:0]capDI;

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
    if (spi_cpu_inst.cpu_rdy && spi_cpu_inst.cpu_inst.PC == 'h3469+1) begin
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

//    if (spi_cpu_inst.cpu_rdy)
//        assert(spi_cpu_inst.cache_inst.mem_rdata == spi_cpu_inst.cache_inst.rdata) else
//            $display("oops");

    if (spi_cpu_inst.cpu_rdy) begin
        capAB <= spi_cpu_inst.cpu_inst.AB;
        capDI <= spi_cpu_inst.cpu_inst.DI;
    end
//    if (capAB == 'h0500 && capDI == 'hd8)
//        $finish(2);
end

initial begin
    $readmemh(tb_rel_path("../mem-files/6502_functional_test.mem"), mem, 0, $size(mem)-1);
    mem['hfffc] = 8'h00;
    mem['hfffd] = 8'h04;

    if ((IODELAY >= 3 && IODELAY < 8) || IODELAY >= 13)
        gpin[2] = 1;
    if (IODELAY >= 10)
        gpin[3] = 1;

//    for (int i=0; i<16; ++i)
//        spi_cpu_inst.cache_inst.cache_line_inst0.block[i] = mem[16'h0400+i];

//    spi_cpu_inst.cache_inst.cache_line_inst0.btag = 12'h040;
//    spi_cpu_inst.cache_inst.cache_line_inst0.bvalid = 1;

    spi_cpu_inst.cpu_inst.AXYS[1] = 8'hff;
    spi_cpu_inst.cpu_inst.PC = 16'h1234;

    if(tb_enable_dumpfile("tb_spi_functional.vcd"))
        $dumpvars(0, tb_spi_functional);

//#1391;
//    spi_cpu_inst.cache_inst.rdata = 8'bxx;

//    #492 spi_cpu_inst.spi_sram_master_inst.rdata_load = 1;
//    #(932-492) spi_cpu_inst.spi_sram_master_inst.rdata_load = 1;
//    #(6212-932) spi_cpu_inst.spi_sram_master_inst.rdata_load = 1;
//    $monitor("%s %0x %0x", spi_cpu_inst.cpu_inst.statename, spi_cpu_inst.cpu_inst.AB, spi_cpu_inst.cpu_inst.DI);
//    $monitor("%s %0x %0x", spi_cpu_inst.cpu_inst.statename, capAB, capDI);


    //#13000 spi_cpu_inst.cache_inst.cache_line_inst0.flargmarg = 0;

//    #5142000;
//    #0;
end

endmodule
`resetall
