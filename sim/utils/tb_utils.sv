// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2024 Anders <anders-code@users.noreply.github.com>

`resetall
`timescale 1ns/1ps
`default_nettype none

package tb_utils_private;
    bit assdie  = 0;
    int asstot  = 0;
    int asspass = 0;
    int assfail = 0;    
endpackage

package tb_utils;
    import tb_utils_private::*;

    task automatic tb_asspass(input string a, input string f, input int n);
        ++asstot;
        ++asspass;
    endtask
    
    task automatic tb_assfail(input string a, input string f, input int n);
        ++asstot;
        ++assfail;
        $display("Error: assert failed: %s at (%s:%0d)",a, f, n);
        if (assdie) begin
            $display("Error: dying now due to failed assert!");
            $finish(2);
        end
    endtask
    
    task automatic tb_assert_report;
        $display("\nAssert report:");
        $display("    passed: %0d/%0d", asspass, asstot);
        $display("    failed: %0d/%0d\n", assfail, asstot);
        if (assfail > 0)
            $display("Error: Failed! bad asserts");
        else if (asstot <= 0)
            $display("Error: Failed! no asserts checked");
        else
            $display("Success! all asserts passed!\n");
    endtask
    
    function automatic string tb_rel_path(input string file);
        string base;
        if ($value$plusargs("basedir=%s", base))
            return {base, "/", file};
        return file;
    endfunction
endpackage
`resetall
