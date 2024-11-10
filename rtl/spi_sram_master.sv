`resetall
`default_nettype none

`include "config.vh"
`include "timescale.vh"
`include "async_reset.vh"

module spi_sram_master #(
    parameter REG_RDATA = 0,
    parameter CS_DELAY = 3
) (
    input  wire clk,
    input  wire clkb,
    input  wire rst,
    input  wire en,
    input  wire enb,

    input  wire spi_phase, // 0: falling  1: next rising
    input  wire spi_delay, // 0: no-delay 1: extra clock delay
    input  wire spi_fast,  // 0: 03, none 1: 0b, one-byte turnaround

    output wire cs_n,
    input  wire miso,
    output wire mosi,

    input  wire [23:0]mem_addr,
    input  wire       mem_en,
    input  wire       mem_wr,
    input  wire       mem_rburst,
    input  wire       mem_wburst,
    input  wire  [7:0]mem_wdata,

    output wire       mem_rdy,
    output wire  [7:0]mem_rdata,

    output wire  [7:0]mem_rdata0,
    output wire       mem_rdata_load
);

typedef enum integer {
    IDLE,
    CMDADDR1,
    CMDADDR2,
    DATA1,
    DATA2,
    DATA3,
    DATA_WBURST,
    DATA_RBURST,
    DELAY1,
    DELAY2,
    DELAY3
} State_Type;

State_Type state;

State_Type next_state;

logic ready_sm;
logic cs_n_sm;

logic counter_reset;
logic [5:0]counter_reset_val;

logic data_shift;
logic data_load;
logic rdata_load;
logic [39:0]data_load_val;

reg counter_done;
reg cur_wr;
reg rd_delay;
reg rd_delay2;

localparam WRITE_CMD     = 8'h02;
localparam READ_CMD      = 8'h03;
localparam FAST_READ_CMD = 8'h0b;

always_comb begin
    next_state = state;

    ready_sm = 0;
    cs_n_sm  = 0;

    counter_reset = 0;
    counter_reset_val = (7-2);

    data_shift = 0;
    data_load  = 0;
    rdata_load = 0;
    data_load_val = 0;

    unique case(state)
        IDLE: begin
            ready_sm = 1;
            cs_n_sm  = 1;

            counter_reset = 1;
            counter_reset_val = (31-2);

            if (mem_en) begin
                data_load = 1;

                if (mem_wr)
                    data_load_val = { WRITE_CMD, mem_addr, mem_wdata };
                else if (!spi_fast)
                    data_load_val = { READ_CMD,  mem_addr, mem_wdata };
                else  begin
                    counter_reset_val = (39-2);
                    data_load_val = { FAST_READ_CMD, mem_addr, mem_wdata };
                end

                next_state = CMDADDR1;
            end
        end

        CMDADDR1: begin
            data_shift = 1;

            if (counter_done)
                next_state = CMDADDR2;
        end

        CMDADDR2: begin
            counter_reset = 1;

            if (rd_delay2)
                counter_reset_val = (8-2);
            else if (rd_delay)
                counter_reset_val = (7-2);
            else
                counter_reset_val = (6-2);

            data_shift = 1;

            next_state = DATA1;
        end

        DATA1: begin
            data_shift = 1;

            if (counter_done)
                next_state = DATA2;
        end

        DATA2: begin
            data_shift = 1;

            if (mem_en && mem_wburst)
                next_state = DATA_WBURST;
            else begin
                cs_n_sm = rd_delay2 && !mem_rburst;
                next_state = DATA3;
            end
        end

        DATA3: begin
            counter_reset = 1;
            counter_reset_val = (CS_DELAY-2);

            data_shift = 1;
            rdata_load = 1;

            if (mem_en && mem_rburst)
                next_state = DATA_RBURST;
            else begin
                cs_n_sm = rd_delay && !mem_rburst;
                next_state = CS_DELAY > 0 ? DELAY1 : IDLE;
            end
        end

        DATA_WBURST: begin
            ready_sm = 1;

            counter_reset = 1;
            counter_reset_val = (6-2);

            data_load = 1;
            data_load_val = { mem_wdata, mem_addr, 8'h81 };

            next_state = DATA1;
        end

        DATA_RBURST: begin
            ready_sm = 1;

            counter_reset = 1;
            counter_reset_val = (5-2);

            data_shift = 1;

            next_state = DATA1;
        end

        DELAY1: begin
            ready_sm = 1;
            cs_n_sm  = 1;

            if (mem_en) begin
                data_load = 1;

                if (mem_wr)
                    data_load_val = { WRITE_CMD, mem_addr, mem_wdata };
                else if (!spi_fast)
                    data_load_val = { READ_CMD,  mem_addr, mem_wdata };
                else
                    data_load_val = { FAST_READ_CMD, mem_addr, mem_wdata };

                if (counter_done || CS_DELAY < 2)
                    next_state = DELAY3;
                else
                    next_state = DELAY2;
            end
            else if (counter_done)
                next_state = IDLE;
        end

        DELAY2: begin
            ready_sm = 0;
            cs_n_sm  = 1;

            if (counter_done)
                next_state = DELAY3;
        end

        DELAY3: begin
            ready_sm = 0;
            cs_n_sm  = 1;

            counter_reset = 1;
            if (!cur_wr && spi_fast)
                counter_reset_val = (39-2);
            else
                counter_reset_val = (31-2);

            next_state = CMDADDR1;
        end
    endcase
end


// state register
always_ff @(posedge clk `ASYNC(posedge rst)) begin
    if (rst)
        state <= IDLE;
    else if (en)
        state <= next_state;
end

always_ff @(posedge clk) begin
    if (en && ready_sm) begin
       cur_wr    <= mem_wr;
       rd_delay  <= !mem_wr && (spi_delay || spi_phase);
       rd_delay2 <= !mem_wr && (spi_delay && spi_phase);
    end
end

reg [5:0]counter;
always_ff @(posedge clk) begin
    if (en && counter_reset)
        { counter_done, counter } <= { 1'b0, counter_reset_val };
    else if (en)
        { counter_done, counter } <= counter - 1;
end

reg miso_falling;
always_ff @(posedge clkb) begin
    miso_falling <= miso;
end

wire miso_sel = spi_phase ? miso_falling : miso;

reg [39:0]data;
always_ff @(posedge clk) begin
    if (en) begin
        if (data_load)
            data <= data_load_val;
        else if (data_shift)
            data <= { data, miso_sel };
    end
end

reg dout;
always_ff @(posedge clkb) begin
    if (enb)
        dout <= data[39];
end

reg cs_n_out;
always_ff @(posedge clkb) begin
    if (enb)
        cs_n_out <= cs_n_sm;
end

assign cs_n = cs_n_out;
assign mosi = dout;

assign mem_rdy    = ready_sm;
assign mem_rdata  = data[7:0];

assign mem_rdata0     = { data[6:0], miso_sel };
assign mem_rdata_load = rdata_load;

endmodule
`resetall
