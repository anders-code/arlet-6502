`resetall
`default_nettype none

`include "config.vh"
`include "timescale.vh"

module spi_cpu_6502 (
    input  wire clk,
    input  wire rst,
    input  wire nmi,
    input  wire irq,
    output wire cs_n,
    output wire mosi,
    input  wire miso
);

wire [15:0]cpu_addr;
wire       cpu_en;
wire       cpu_wr;
wire       cpu_iread;
wire  [7:0]cpu_wdata;
wire  [7:0]cpu_rdata;
wire       cpu_rdy;

cpu_6502 cpu_inst (
    .clk,
    .reset (rst),
    .AB    (cpu_addr),
    .DI    (cpu_rdata),
    .DO    (cpu_wdata),
    .WE    (cpu_wr),
    .IRQ   (irq),
    .NMI   (nmi),
    .RDY   (cpu_rdy),
    .SYNC  (),
    .IREAD (cpu_iread),
    .MEN   (cpu_en)
);

wire [23:0]mem_addr;
wire       mem_en;
wire       mem_rdy;
wire       mem_wr;
wire       mem_rburst;
wire       mem_wburst;
wire  [7:0]mem_wdata;
wire  [7:0]mem_rdata;
wire  [7:0]mem_rdata0;
wire       mem_rdata_load;

cache_6502 cache_inst (
    .clk,
    .rst,
    .cpu_addr,
    .cpu_en,
    .cpu_wr,
    .cpu_iread,
    .cpu_wdata,
    .cpu_rdy,
    .cpu_rdata,
    .mem_addr,
    .mem_en,
    .mem_wr,
    .mem_rburst,
    .mem_wburst,
    .mem_wdata,
    .mem_rdy,
    .mem_rdata,
    .mem_rdata0,
    .mem_rdata_load
);

spi_sram_master spi_sram_master_inst (
    .clk,
    .clkb  (~clk),
    .rst,
    .en    (1'b1),
    .enb   (1'b1),
    .cs_n,
    .miso,
    .mosi,
    .mem_addr,
    .mem_en,
    .mem_wr,
    .mem_rburst,
    .mem_wburst,
    .mem_wdata,
    .mem_rdy,
    .mem_rdata,
    .mem_rdata0,
    .mem_rdata_load
);

endmodule
`resetall
