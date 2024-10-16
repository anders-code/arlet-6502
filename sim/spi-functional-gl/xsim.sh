#!/bin/sh -x

TOP="tb_spi_functional_gl"

rm -fr xsim.dir/

/opt/Xilinx/Vivado/2023.1/bin/xvlog -sv -relax -nolog -i ../.. -d TIMING=1 -d USE_POWER_PINS=1 sky130_fd_sc_hd.v primitives.v tt_um_anders_tt_6502.pnl.v ../../rtl/spi_sram_slave.sv ../utils/tb*.sv "${TOP}.sv"
rm -f *.pb *.jou

/opt/Xilinx/Vivado/2023.1/bin/xelab -debug off -relax -nolog -snapshot "${TOP}" -top "${TOP}" -timescale 1ps/1ps -transport_int_delays -pulse_r 0 -pulse_int_r 0 -sdftyp tt_um_anders_tt_6502__nom_tt_025C_1v80.sdf -sdfroot "/${TOP}/tt_6502_inst"
#/opt/Xilinx/Vivado/2023.1/bin/xelab -debug typical -relax -nolog -snapshot "${TOP}" -top "${TOP}" -timescale 1ps/1ps -transport_int_delays -pulse_r 0 -pulse_int_r 0
rm -f *.pb *.jou

if [ -z "$1" ]; then
    set -- -R;
fi
/opt/Xilinx/Vivado/2023.1/bin/xsim -nolog "${TOP}" "$@"
rm -f *.pb *.jou
