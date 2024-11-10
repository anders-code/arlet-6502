// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Anders <anders-code@users.noreply.github.com>

`resetall
`default_nettype none

`include "config.vh"
`include "timescale.vh"
`include "async_reset.vh"

module regs_6502 #(
    parameter ENABLE_UPAD  = 1,
    parameter ENABLE_UPAI  = 1,
    parameter ENABLE_UPAZO = 1
) (
    input  wire clk,
    input  wire rst,

    input  wire [15:0]cpu_addr,
    input  wire       cpu_en,
    input  wire       cpu_wr,
    input  wire  [7:0]cpu_wdata,
    input wire        cpu_rdy,

    output wire       int_en,
    output wire  [7:0]int_rdata,

    output wire       icache_en, // df00[0]
    output wire       skip_int,  // df00[1]
    output wire       spi_phase, // df00[2]
    output wire       spi_delay, // df00[3]
    output wire       spi_fast,  // df00[4]

    output wire  [7:0]upad,      // df01
    output wire  [7:0]upai,      // df02
    output wire  [7:0]upazo,     // df03

    input  wire  [7:0]gpin,      // df04
    output wire  [7:0]gpout,     // df05

    input  wire  [3:0]gpio_in,   // df06
    output wire  [3:0]gpio_oe,   // df07[7:4]
    output wire  [3:0]gpio_out   // df07[3:0]
);

assign int_en = (cpu_addr[15:8] == 8'hdf); // 16'hdf00

reg first;
always_ff @(posedge clk `ASYNC(posedge rst)) begin
    if (rst)
        first <= 1;
    else
        first <= 0;
end

reg [7:0]csr_r;
reg [7:0]upad_r;
reg [7:0]upai_r;
reg [7:0]upazo_r;
reg [7:0]gpout_r;
reg [7:0]gpio_r;
always_ff @(posedge clk) begin
    if (first) begin
        csr_r   <= gpin;
        upad_r  <= 8'h00;
        upai_r  <= 8'h00;
        upazo_r <= 8'h00;
        gpout_r <= 8'h00;
        gpio_r  <= 8'h00;
    end
    else if (int_en && cpu_en && cpu_rdy && cpu_wr) begin
        unique case (cpu_addr[2:0])
            3'h0: csr_r   <= cpu_wdata;
            3'h1: upad_r  <= cpu_wdata;
            3'h2: upai_r  <= cpu_wdata;
            3'h3: upazo_r <= cpu_wdata;
            3'h5: gpout_r <= cpu_wdata;
            3'h7: gpio_r  <= cpu_wdata;
            default: ;
        endcase
    end
end

// invalidate icache when writing to reg[2]
wire icache_inv = (int_en && cpu_en && cpu_rdy && cpu_wr && cpu_addr[2:0] == 3'h2);

logic [7:0]rdata;
always_comb begin
    unique case (cpu_addr[2:0])
        3'h0: rdata = csr_r;
        3'h1: rdata = upad;
        3'h2: rdata = upai;
        3'h3: rdata = upazo;
        3'h4: rdata = gpin;
        3'h5: rdata = gpout_r;
        3'h6: rdata = { 4'b0, gpio_in };
        3'h7: rdata = gpio_r;
    endcase
end

assign int_rdata = rdata;

assign icache_en = csr_r[0] && !icache_inv;
assign skip_int  = csr_r[1];
assign spi_phase = csr_r[2];
assign spi_delay = csr_r[3];
assign spi_fast  = csr_r[4];

assign upad      = ENABLE_UPAD  ? upad_r  : 8'b0;
assign upai      = ENABLE_UPAI  ? upai_r  : 8'b0;
assign upazo     = ENABLE_UPAZO ? upazo_r : 8'b0;

assign gpout     = gpout_r;
assign gpio_oe   = gpio_r[7:4];
assign gpio_out  = gpio_r[3:0];

endmodule
`resetall
