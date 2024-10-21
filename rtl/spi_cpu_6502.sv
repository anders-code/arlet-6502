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

wire [23:0]mem_addr;
wire       mem_en = 1;
wire       mem_wr;
wire  [7:0]mem_wdata;
wire  [7:0]mem_rdata;

wire rdy;

cpu_6502 cpu_inst (
    .clk,
    .reset (rst),
    .AB  (mem_addr[15:0]),
    .DI  (mem_rdata),
    .DO  (mem_wdata),
    .WE  (mem_wr),
    .IRQ (irq),
    .NMI (nmi),
    .RDY (rdy)
);

assign mem_addr[23:16] = 0;

reg last_we;
reg [15:0]last_addr;
always_ff @(posedge clk) begin
    if (rdy) begin
        last_we <= mem_wr;
        last_addr <= mem_addr[15:0] + 1;
    end
end

wire mem_burst = (mem_wr == last_we && mem_addr[15:0] == last_addr);

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
    .mem_rburst (mem_burst),
    .mem_wburst (1'b0),
    .mem_wdata,
    .mem_rdy    (rdy),
    .mem_rdata,
    .mem_rdata0 (),
    .mem_rdata_load ()
);

endmodule
`resetall
