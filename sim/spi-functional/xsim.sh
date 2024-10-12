#!/bin/sh -x

TOP="tb_spi_functional"

rm -fr xsim.dir/

/opt/Xilinx/Vivado/2023.1/bin/xvlog -sv -relax -nolog -i ../.. -d SIM ../../rtl/*.sv ../utils/tb*.sv "${TOP}.sv"
rm -f *.pb *.jou

/opt/Xilinx/Vivado/2023.1/bin/xelab -debug off -relax -nolog -snapshot "${TOP}" -top "${TOP}"
rm -f *.pb *.jou

/opt/Xilinx/Vivado/2023.1/bin/xsim -nolog "${TOP}" "${1:--R}"
rm -f *.pb *.jou
