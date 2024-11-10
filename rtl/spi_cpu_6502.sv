`resetall
`default_nettype none

`include "config.vh"
`include "timescale.vh"

module spi_cpu_6502 (
    input  wire clk,
    input  wire arst_n,
    input  wire nmi,
    input  wire irq,
    output wire cs_n,
    output wire mosi,
    input  wire miso,
    output wire sync,

    input  wire  [7:0]gpin,
    output wire  [7:0]gpout,
    input  wire  [3:0]gpio_in,
    output wire  [3:0]gpio_oe,
    output wire  [3:0]gpio_out
);

wire rst;

reset_sync reset_sync_inst (
    .clk,
    .arst_n,
    .rst
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
    .SYNC  (sync),
    .IREAD (cpu_iread),
    .MEN   (cpu_en)
);

wire       int_en;
wire  [7:0]int_rdata;
wire       icache_en;
wire       skip_int;
wire       spi_phase;
wire       spi_delay;
wire       spi_fast;
wire  [7:0]upad;
wire  [7:0]upai;
wire  [7:0]upazo;

regs_6502 #(
    .ENABLE_UPAI  (0),
    .ENABLE_UPAD  (1),
    .ENABLE_UPAZO (0)
) regs_6502_inst (
    .clk,
    .rst,
    .cpu_addr,
    .cpu_en,
    .cpu_wr,
    .cpu_wdata,
    .cpu_rdy,
    .int_en,
    .int_rdata,
    .icache_en,
    .skip_int,
    .spi_phase,
    .spi_delay,
    .spi_fast,
    .upad,
    .upai,
    .upazo,
    .gpin,
    .gpout,
    .gpio_in,
    .gpio_oe,
    .gpio_out
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
    .icache_en,
    .skip_int,
    .cpu_addr,
    .cpu_en,
    .cpu_wr,
    .cpu_iread,
    .cpu_wdata,
    .cpu_rdy,
    .cpu_rdata,
    .int_en,
    .int_rdata,
    .upad,
    .upai,
    .upazo,
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

spi_sram_master #(
    .CS_DELAY (0)
) spi_sram_master_inst (
    .clk,
    .clkb  (~clk),
    .rst,
    .en    (1'b1),
    .enb   (1'b1),
    .spi_phase,
    .spi_delay,
    .spi_fast,
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
