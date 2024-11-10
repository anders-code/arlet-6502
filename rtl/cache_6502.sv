`resetall
`default_nettype none

`include "config.vh"
`include "timescale.vh"
`include "async_reset.vh"

module cache_6502 (
    input  wire clk,
    input  wire rst,

    input  wire icache_en,
    input  wire skip_int,

    input  wire [15:0]cpu_addr,
    input  wire       cpu_en,
    input  wire       cpu_wr,
    input  wire       cpu_iread,
    input  wire  [7:0]cpu_wdata,
    output wire       cpu_rdy,
    output wire  [7:0]cpu_rdata,

    input  wire       int_en,
    input  wire  [7:0]int_rdata,

    input  wire  [7:0]upad,
    input  wire  [7:0]upai,
    input  wire  [7:0]upazo,

    output wire [23:0]mem_addr,
    output wire       mem_en,
    output wire       mem_wr,
    output wire       mem_rburst,
    output wire       mem_wburst,
    output wire  [7:0]mem_wdata,
    input  wire       mem_rdy,
    input  wire  [7:0]mem_rdata,
    input  wire  [7:0]mem_rdata0,
    input  wire       mem_rdata_load
);

typedef enum integer {
    READY,
    MEM_WAIT,
    IFILL
} State_Type;

State_Type  state;

reg    [2:0]saved_addr;
reg    [2:0]fill_off;

wire        fill_done;

wire   [7:0]cache_rdata;
wire        cache_hit;

logic  [7:0]upa;

State_Type  next_state;

logic       fill_reset;
logic       fill_tag_en;
logic       fill_en;

logic       cpu_rdy_sm;

logic [23:0]mem_addr_sm;
logic       mem_en_sm;
logic       mem_rburst_sm;

logic  [7:0]rdata_next;
logic       rdata_load;

always_comb begin
    next_state = state;

    fill_en     = 0;
    fill_tag_en = 0;
    fill_reset  = 1;

    cpu_rdy_sm  = 0;

    mem_addr_sm   = { upa, cpu_addr };
    mem_en_sm     = 0;
    mem_rburst_sm = 0;

    rdata_next   = mem_rdata0;
    rdata_load   = mem_rdata_load;

    unique case(state)
        READY: begin
            cpu_rdy_sm = 1;

            rdata_next = cache_rdata;

            if (!cpu_en && skip_int)
                next_state  = READY; // skip cycle (typically REG)
            else if (int_en) begin
                rdata_next  = int_rdata;
                rdata_load  = 1; // latch internal mem rdata
                next_state  = READY; // complete cycle
            end
            else if (icache_en && cache_hit && !cpu_wr) begin
                rdata_load  = 1; // latch cached entry
                next_state  = READY; // complete cycle
            end
            else if (icache_en && cpu_iread) begin
                mem_addr_sm = { upa, cpu_addr[15:3], 3'b0 };

                fill_reset  = 0;
                fill_tag_en = 1;

                mem_en_sm   = 1; // start memory transaction
                next_state  = IFILL;
            end
            else begin
                mem_en_sm   = 1; // start memory transaction
                next_state  = MEM_WAIT;
            end
        end

        MEM_WAIT: begin
            mem_en_sm  = 1;

            rdata_next = mem_rdata0;
            rdata_load = mem_rdata_load;

            if (mem_rdata_load)
                next_state = READY;
        end

        IFILL: begin
            mem_en_sm     = !fill_done;
            mem_rburst_sm = !fill_done;

            rdata_next    = mem_rdata0;
            rdata_load    = mem_rdata_load && (fill_off == saved_addr); // load requested by as it flys by

            fill_reset    = mem_rdata_load && fill_done;
            fill_en       = mem_rdata_load;

            if (mem_rdata_load && fill_done)
                next_state = READY;
        end
    endcase
end


// state register
always_ff @(posedge clk `ASYNC(posedge rst)) begin
    if (rst)
        state <= READY;
    else
        state <= next_state;
end

// memory mux and register
reg [7:0]rdata;
always_ff @(posedge clk) begin
    if (rdata_load)
        rdata <= rdata_next;
end

// count bytes during fill
wire [2:0]fill_off_next;

always_ff @(posedge clk) begin
    if (fill_reset)
        fill_off <= 0;
    else if (fill_en)
        fill_off <= fill_off_next;
end

assign { fill_done, fill_off_next } = fill_off + 1;

// saved request addr
always_ff @(posedge clk) begin
    if (fill_tag_en)
        saved_addr <= cpu_addr[2:0];
end

// upper address byte (instruction, zero/stack, or data)
always_comb begin
    if (cpu_iread)
        upa = upai;
    else if ({ cpu_addr[15:9], 1'b0 } == 8'b0)
        upa = upazo;
    else
        upa = upad;
end

// icache lines
wire [1:0]cache_line_hit;
wire [7:0]cache_line_rdata[2];

reg [1:0]fill_line_en;

cache_line #(
    .TAG_WIDTH  (13),
    .BLOCK_SIZE (8)
) icache_line_inst_0 (
    .clk,
    .rst          (rst || !icache_en),
    .wr           (cpu_wr),
    .fill_line_en (fill_line_en[0]),
    .tag          (cpu_addr[15:3]),
    .off          (cpu_addr[2:0]),
    .fill_tag_en  (fill_tag_en),
    .fill_en      (fill_en),
    .fill_off,
    .fill_data    (mem_rdata0),
    .cache_hit    (cache_line_hit[0]),
    .cache_rdata  (cache_line_rdata[0])
);

cache_line #(
    .TAG_WIDTH  (13),
    .BLOCK_SIZE (8)
) icache_line_inst_1 (
    .clk,
    .rst          (rst || !icache_en),
    .wr           (cpu_wr),
    .fill_line_en (fill_line_en[1]),
    .tag          (cpu_addr[15:3]),
    .off          (cpu_addr[2:0]),
    .fill_tag_en  (fill_tag_en),
    .fill_en      (fill_en),
    .fill_off,
    .fill_data    (mem_rdata0),
    .cache_hit    (cache_line_hit[1]),
    .cache_rdata  (cache_line_rdata[1])
);

// mux hit cache data
assign cache_rdata = cache_line_hit[1] ? cache_line_rdata[1] : cache_line_rdata[0];

// combine any hit
assign cache_hit   = |cache_line_hit;

// track plru
always_ff @(posedge clk `ASYNC(posedge rst)) begin
    if (rst)
        fill_line_en <= 2'b01;
    else if (!icache_en)
        fill_line_en <= 2'b01;
    else if (cpu_rdy_sm && cpu_en && !cpu_wr) begin
        unique case(cache_line_hit)
            2'b00: fill_line_en <= fill_line_en;
            2'b01: fill_line_en <= 2'b10;
            2'b10: fill_line_en <= 2'b01;
            2'b11: fill_line_en <= 2'b01; // error, should not occur
        endcase
    end
    else if (mem_rdata_load && fill_done)
        fill_line_en <= ~fill_line_en;
end

// feed-thru from cpu to mem
assign mem_wr     = cpu_wr;
assign mem_wburst = 0;
assign mem_wdata  = cpu_wdata;

// mux from cpu or cache-control
assign mem_addr   = mem_addr_sm;
assign mem_en     = mem_en_sm;
assign mem_rburst = mem_rburst_sm;

// mux fom mem or cache-control
assign cpu_rdy   = cpu_rdy_sm;
assign cpu_rdata = rdata;

endmodule
`resetall
