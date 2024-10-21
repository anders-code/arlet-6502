`resetall
`default_nettype none

`include "config.vh"
`include "timescale.vh"
`include "async_reset.vh"

module spi_sram_master #(
    parameter REG_RDATA = 0
) (
    input  wire clk,
    input  wire clkb,
    input  wire rst,
    input  wire en,
    input  wire enb,

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
logic [4:0]counter_reset_val;

logic data_shift;
logic data_load;
logic rdata_load;
logic [39:0]data_load_val;

reg counter_done;


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
                    data_load_val = { 8'h82, mem_addr, mem_wdata };
                else
                    data_load_val = { 8'h83, mem_addr, 8'h81 }; // TODO: cmd rdata

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
            else
                next_state = DATA3;
        end

        DATA3: begin
            counter_reset = 1;
            counter_reset_val = (3-2);

            data_shift = 1;
            rdata_load = 1;

            if (mem_en && mem_rburst)
                next_state = DATA_RBURST;
            else
                next_state = DELAY1;
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
                    data_load_val = { 8'h82, mem_addr, mem_wdata };
                else
                    data_load_val = { 8'h83, mem_addr, 8'h81 }; // TODO: cmd rdata

                if (counter_done)
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

reg [4:0]counter;
always_ff @(posedge clk) begin
    if (en && counter_reset)
        { counter_done, counter } <= { 1'b0, counter_reset_val };
    else if (en)
        { counter_done, counter } <= counter - 1;
end

reg [39:0]data;
always_ff @(posedge clk) begin
    if (en) begin
        if (data_load)
            data <= data_load_val;
        else if (data_shift)
            data <= { data, miso };
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

assign mem_rdata0     = { data[6:0], miso };
assign mem_rdata_load = rdata_load;

endmodule
`resetall
