// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Anders <anders-code@users.noreply.github.com>

`resetall
`timescale 1ns/1ps
`default_nettype none


module tb_functional (
    input wire clk,
    input wire rst
);

tb_clkrst clkrst_inst (.clk, .rst);

import tb_utils::*;

wire  [15:0]ab;
wire   [7:0]dout;
wire   [7:0]din;
wire        we;
wire        sync;
wire        iread;
wire        men;

logic       irq = 0;
logic       nmi = 0;
logic       rdy = 1;

cpu_6502 cpu_inst (
  .clk   (clk),
  .reset (rst),
  .AB    (ab),
  .DI    (din),
  .DO    (dout),
  .WE    (we),
  .IRQ   (irq),
  .NMI   (nmi),
  .RDY   (rdy),
  .SYNC  (sync),
  .IREAD (iread),
  .MEN   (men)
);

int nomencnt = 0;
reg last_sync;
reg [15:0]last_ab;
always @(posedge clk) begin
    if (rdy)
        last_sync <= sync;
        
    if (rdy)
        last_ab <= ab;
    if (rdy && !men)
        ++nomencnt;
    
    if ($time > 120) begin
        assert(!(cpu_inst.state == cpu_inst.DECODE && !last_sync)) else 
            $error("cpu_state1");
    
        assert(!(cpu_inst.state != cpu_inst.DECODE && last_sync)) else 
            $error("cpu_state2");
            
        assert(!(we && !men)) else
            $error("we no men");
            
        assert(!(iread && !men)) else
            $error("iread no men");
            
        assert(!(iread && we)) else
            $error("iread no men");                             
            
        assert(!(men && iread && ab != cpu_inst.PC_temp)) else
            $error("oops %0b %0h %0h %s", iread, ab, cpu_inst.PC_temp, cpu_inst.statename);
        assert(!(men && !iread && ab == cpu_inst.PC_temp)) else
            $error("!oops %0b %0h %0h %s", iread, ab, cpu_inst.PC_temp, cpu_inst.statename);
        end
end

//wire [15:0]ab2 = (!iread && ab == cpu_inst.PC_temp) ? last_ab : ab;

reg [7:0]mem[64*1024];
reg [7:0]memout;
always_ff @(posedge clk) begin
    if (men && rdy) begin
        if (we)
            mem[ab] <= dout;
        memout <= mem[ab];
    end
end
assign din = memout;

wire [7:0]tc = mem['h0200];
reg [7:0]lasttc = 0;
time lasttm = 100;
time lasttm2 = 0;
int termcnt = 0;
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
    if (cpu_inst.PC == 'h3469+1) begin
        // http://forum.6502.org/viewtopic.php?f=8&t=6202#p90723
        // 10 cycles of reset + 6 cycles before executing 0400 
        if (termcnt == 0)
            $display("\nSuccess! cycles %0d (ideal 96241364) %0d\n", $time/10 - 16, nomencnt);
        else if (termcnt >= 2)
            $finish(2);

        termcnt <= termcnt + 1;
    end
end

initial begin
    $readmemh(tb_rel_path("../mem-files/6502_functional_test.mem"), mem, 0, $size(mem)-1);

    mem['hfffc] = 8'h00; // modify reset vector to start at 0400
    mem['hfffd] = 8'h04;

    if (tb_enable_dumpfile("tb_functional.vcd"))
        $dumpvars(0, tb_functional);
end

endmodule
`resetall
