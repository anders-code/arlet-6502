`resetall
`default_nettype none

`include "config.vh"
`include "timescale.vh"
`include "async_reset.vh"

module cache_line #(
    parameter TAG_WIDTH     = 13,
    parameter BLOCK_SIZE    = 8,
    localparam OFFSET_WIDTH = $clog2(BLOCK_SIZE),
    localparam TMSB = TAG_WIDTH-1,
    localparam OMSB = OFFSET_WIDTH-1
) (
    input  wire clk,
    input  wire rst,
    
    input  wire wr,
    input  wire fill_line_en,

    input  wire [TMSB:0]tag,
    input  wire [OMSB:0]off,

    input  wire         fill_tag_en,
    input  wire         fill_en,
    input  wire [OMSB:0]fill_off,
    input  wire    [7:0]fill_data,

    output wire         cache_hit,
    output wire    [7:0]cache_rdata
);

reg valid;
always_ff @(posedge clk `ASYNC(posedge rst)) begin
    if (rst)
        valid <= 0;
    else if (fill_line_en && fill_tag_en)
        valid <= 1;
    else if (cache_hit && wr)
        valid <= 0;
end

reg [TMSB:0]block_tag;
always_ff @(posedge clk) begin
    if (fill_line_en && fill_tag_en)
        block_tag <= tag;
end

reg [7:0]block[BLOCK_SIZE];
always_ff @(posedge clk) begin
    if (fill_line_en && fill_en)
        block[fill_off] <= fill_data;
end

// async memory reads (to be registered outside)
assign cache_rdata = block[off];

assign cache_hit = (tag == block_tag) && valid;

endmodule
`resetall
