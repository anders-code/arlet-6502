`resetall
`timescale 1ns / 1ps
`default_nettype none

`include "sim/utils/tb_assert.vh"

module tb_spi_sram();

import tb_utils::*;

// insure clock starts without posedge @ time 0 to avoid race conditions
// first posedge will be @PERIOD ns
logic clki;
always begin
    #5 clki = 0;
    #5 clki = 1;
end

wire clk;
assign #1 clk = clki;

logic rst;

logic en;
logic cs_n;
wire mosi;
wire miso;

wire [23:0]mem_addr;
wire       mem_en;
wire       mem_wr;
wire  [7:0]mem_wdata;
reg   [7:0]mem_rdata;

spi_sram_slave spi_sram_slave_inst (
   .clk,
   .clkb (~clk),
   .rst,
   .en,
   .enb (en),
   .cs_n,
   .mosi,
   .miso,
   .mem_addr,
   .mem_en,
   .mem_wr,
   .mem_wdata,
   .mem_rdata
);


reg [7:0]mem[64*1024];
always_ff @(posedge clk) begin
    if (mem_en) begin
        if (mem_wr)
            mem[mem_addr[15:0]] <= mem_wdata;
        mem_rdata <= mem[mem_addr[15:0]];
    end
end

reg [63:0]shift_data;

initial begin
    if (tb_enable_dumpfile("tb_spi_sram.vcd"))
        $dumpvars(0, tb_spi_sram);

    #17 rst  = 1;
        en   = 0;
        cs_n = 1;
        mem['h407] = 'h77;
        mem['h408] = 'h88;
        mem['h409] = 'h99;
        mem['h40a] = 'haa;
        mem['h40b] = 'hbb;
        mem['h40c] = 'hcc;

   #100 rst = 0;
        en  = 1;

   #100 shift_data = { 8'h83, 24'h800409, 32'b0 };
        cs_n = 0;
   #480 cs_n = 1;

   #100 shift_data = { 8'h82, 24'h800405, 32'h11223344 };
        cs_n = 0;
   #640 cs_n = 1;

   #100 shift_data = { 8'h83, 24'h800405, 32'b0 };
        cs_n = 0;
   #640 cs_n = 1;

  #1000 `tb_assert(shift_data == 64'h00000000_11223344);
        tb_assert_report;
        $finish(2);
end

always @(negedge clk) begin
    if (!cs_n)
        shift_data <= { shift_data, miso };
end
assign mosi = shift_data[63];

endmodule
`resetall
